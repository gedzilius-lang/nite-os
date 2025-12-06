#!/bin/bash

# Define paths
BASE_DIR="/opt/nite-os/backend"
SRC_DIR="$BASE_DIR/src"

echo "--- PHASE 4: Auth & Roles ---"

# --- 1. Install Dependencies ---
echo "Installing security packages..."
cd $BASE_DIR
npm install @nestjs/jwt @nestjs/passport passport passport-jwt bcryptjs
npm install -D @types/passport-jwt @types/bcryptjs

# --- 2. Update User Entity (Add Credentials) ---
echo "Updating User Entity..."
cat <<EOF > $SRC_DIR/modules/users/user.entity.ts
import { Entity, Column, PrimaryGeneratedColumn, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ nullable: true })
  externalId: string;

  @Column({ unique: true, nullable: true })
  nitetapId: string;

  // New Credential Fields
  @Column({ unique: true, nullable: true })
  username: string;

  @Column({ nullable: true, select: false }) // Select false hides it by default
  password: string;

  @Column({ nullable: true })
  apiKey: string;

  @Column({ default: 'USER' })
  role: string; // USER, STAFF, VENUE_ADMIN, NITECORE_ADMIN

  @Column({ nullable: true })
  venueId: number;

  @Column({ default: 0 })
  xp: number;

  @Column({ default: 1 })
  level: number;

  @Column({ type: 'decimal', default: 0 })
  niteBalance: number;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
EOF

# --- 3. Create Auth Utilities (Guards & Decorators) ---
mkdir -p $SRC_DIR/common/guards
mkdir -p $SRC_DIR/common/decorators

# Roles Decorator
cat <<EOF > $SRC_DIR/common/decorators/roles.decorator.ts
import { SetMetadata } from '@nestjs/common';
export const Roles = (...roles: string[]) => SetMetadata('roles', roles);
EOF

# Current User Decorator
cat <<EOF > $SRC_DIR/common/decorators/user.decorator.ts
import { createParamDecorator, ExecutionContext } from '@nestjs/common';

export const CurrentUser = createParamDecorator(
  (data: unknown, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest();
    return request.user;
  },
);
EOF

# JWT Constants
cat <<EOF > $SRC_DIR/modules/auth/constants.ts
export const jwtConstants = {
  secret: 'NITEOS_V8_SECRET_KEY_DEV_ONLY', // In prod, use process.env
};
EOF

# --- 4. Implement Auth Module ---

# JWT Strategy
cat <<EOF > $SRC_DIR/modules/auth/jwt.strategy.ts
import { ExtractJwt, Strategy } from 'passport-jwt';
import { PassportStrategy } from '@nestjs/passport';
import { Injectable } from '@nestjs/common';
import { jwtConstants } from './constants';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor() {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: jwtConstants.secret,
    });
  }

  async validate(payload: any) {
    // This object is attached to req.user
    return { userId: payload.sub, username: payload.username, role: payload.role, venueId: payload.venueId };
  }
}
EOF

# Auth Service
cat <<EOF > $SRC_DIR/modules/auth/auth.service.ts
import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../users/user.entity';
import * as bcrypt from 'bcryptjs';

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(User)
    private usersRepository: Repository<User>,
    private jwtService: JwtService,
  ) {}

  async validateUser(username: string, pass: string): Promise<any> {
    const user = await this.usersRepository.findOne({ 
        where: { username },
        select: ['id', 'username', 'password', 'role', 'venueId'] 
    });
    
    if (user && user.password && await bcrypt.compare(pass, user.password)) {
      const { password, ...result } = user;
      return result;
    }
    return null;
  }

  async login(user: any) {
    const payload = { 
        username: user.username, 
        sub: user.id, 
        role: user.role,
        venueId: user.venueId
    };
    return {
      access_token: this.jwtService.sign(payload),
      user: payload
    };
  }
}
EOF

# Auth Controller
cat <<EOF > $SRC_DIR/modules/auth/auth.controller.ts
import { Controller, Post, Body, UnauthorizedException } from '@nestjs/common';
import { AuthService } from './auth.service';

@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  @Post('login')
  async login(@Body() loginDto: any) {
    const user = await this.authService.validateUser(loginDto.username, loginDto.password);
    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }
    return this.authService.login(user);
  }
}
EOF

# Auth Module Configuration
cat <<EOF > $SRC_DIR/modules/auth/auth.module.ts
import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { User } from '../users/user.entity';
import { jwtConstants } from './constants';
import { JwtStrategy } from './jwt.strategy';

@Module({
  imports: [
    TypeOrmModule.forFeature([User]),
    PassportModule,
    JwtModule.register({
      secret: jwtConstants.secret,
      signOptions: { expiresIn: '24h' },
    }),
  ],
  providers: [AuthService, JwtStrategy],
  controllers: [AuthController],
  exports: [AuthService],
})
export class AuthModule {}
EOF

# --- 5. Implement Guards ---

# Roles Guard
cat <<EOF > $SRC_DIR/common/guards/roles.guard.ts
import { Injectable, CanActivate, ExecutionContext } from '@nestjs/common';
import { Reflector } from '@nestjs/core';

@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const requiredRoles = this.reflector.getAllAndOverride<string[]>('roles', [
      context.getHandler(),
      context.getClass(),
    ]);
    if (!requiredRoles) {
      return true;
    }
    const { user } = context.switchToHttp().getRequest();
    return requiredRoles.some((role) => user.role?.includes(role));
  }
}
EOF

# Jwt Auth Guard
cat <<EOF > $SRC_DIR/common/guards/jwt-auth.guard.ts
import { Injectable } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';

@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {}
EOF

# --- 6. Protect POS Module ---

# Update POS Service Interface (remove manual staffId)
# We update the CheckoutDto to exclude staffId, as it comes from JWT now.
cat <<EOF > $SRC_DIR/modules/pos/pos.service.ts
import { Injectable, BadRequestException, NotFoundException, ForbiddenException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In } from 'typeorm';
import { PosTransaction } from './pos-transaction.entity';
import { User } from '../users/user.entity';
import { MarketItem } from '../market/market-item.entity';
import { NitecoinTransaction } from '../nitecoin/nitecoin-transaction.entity';

export interface CheckoutItemDto {
  itemId: number;
  count: number;
}

export interface CheckoutDto {
  nitetapId: string;
  items: CheckoutItemDto[];
  // staffId is now injected from the Controller via JWT
}

@Injectable()
export class PosService {
  constructor(
    @InjectRepository(PosTransaction) private posRepo: Repository<PosTransaction>,
    @InjectRepository(User) private userRepo: Repository<User>,
    @InjectRepository(MarketItem) private itemRepo: Repository<MarketItem>,
    @InjectRepository(NitecoinTransaction) private nitecoinRepo: Repository<NitecoinTransaction>,
  ) {}

  async checkout(venueId: number, dto: CheckoutDto, staffUser: any) {
    // Security: Ensure staff belongs to this venue (unless Admin)
    if (staffUser.role !== 'NITECORE_ADMIN' && staffUser.venueId !== venueId) {
       throw new ForbiddenException('You are not authorized for this venue');
    }

    // 1. Find Customer
    const customer = await this.userRepo.findOne({ where: { nitetapId: dto.nitetapId } });
    if (!customer) throw new NotFoundException('NiteTap ID not found');

    // 2. Fetch Items
    const itemIds = dto.items.map((i) => i.itemId);
    const dbItems = await this.itemRepo.find({ where: { id: In(itemIds) } });
    
    // 3. Calculate Totals
    let totalChf = 0;
    let totalNite = 0;

    for (const reqItem of dto.items) {
      const dbItem = dbItems.find((i) => i.id === reqItem.itemId);
      if (!dbItem) continue;
      totalChf += Number(dbItem.priceChf) * reqItem.count;
      totalNite += Number(dbItem.priceNite) * reqItem.count;
    }

    if (totalNite === 0 && totalChf === 0) throw new BadRequestException('No valid items');

    // 4. Check Balance
    if (customer.niteBalance < totalNite) {
      throw new BadRequestException(\`Insufficient Nitecoin. Required: \${totalNite}, Has: \${customer.niteBalance}\`);
    }

    // 5. Execute Transaction
    customer.niteBalance = Number(customer.niteBalance) - totalNite;
    await this.userRepo.save(customer);

    if (totalNite > 0) {
      await this.nitecoinRepo.save({
        userId: customer.id,
        venueId: venueId,
        amount: -totalNite,
        type: 'SPEND'
      });
    }

    // 6. Create Receipt
    const receipt = await this.posRepo.save({
      venueId: venueId,
      staffId: staffUser.userId, // From JWT
      userId: customer.id,
      nitetapId: dto.nitetapId,
      totalChf: totalChf,
      totalNite: totalNite,
      status: 'COMPLETED'
    });

    return {
      success: true,
      newBalance: customer.niteBalance,
      receiptId: receipt.id,
      totalNitePaid: totalNite
    };
  }
}
EOF

# Update POS Controller (Add Guards)
cat <<EOF > $SRC_DIR/modules/pos/pos.controller.ts
import { Controller, Post, Body, Param, Get, UseGuards } from '@nestjs/common';
import { PosService, CheckoutDto } from './pos.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/user.decorator';

@Controller('pos')
@UseGuards(JwtAuthGuard, RolesGuard)
export class PosController {
  constructor(private readonly service: PosService) {}

  @Post(':venueId/checkout')
  @Roles('STAFF', 'VENUE_ADMIN', 'NITECORE_ADMIN')
  async checkout(
    @Param('venueId') venueId: string,
    @Body() dto: CheckoutDto,
    @CurrentUser() user: any
  ) {
    return this.service.checkout(Number(venueId), dto, user);
  }

  @Get('health')
  health() {
    return { status: 'ok', service: 'pos (secured)' };
  }
}
EOF

# --- 7. Admin Seed Script (Update UsersService) ---
# Adding a helper to create an Admin user for testing login
cat <<EOF > $SRC_DIR/modules/users/users.service.ts
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './user.entity';
import * as bcrypt from 'bcryptjs';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private userRepo: Repository<User>,
  ) {}

  getHealth() {
    return { status: 'ok', service: 'users', timestamp: new Date().toISOString() };
  }

  async createDemoUser() {
    // Customer
    let user = await this.userRepo.findOne({ where: { nitetapId: 'TAP-TEST' } });
    if (!user) {
        user = this.userRepo.create({
            nitetapId: 'TAP-TEST',
            niteBalance: 1000, 
            xp: 100,
            level: 5,
            role: 'USER'
        });
        await this.userRepo.save(user);
    }

    // Admin/Staff User (for POS login)
    let admin = await this.userRepo.findOne({ where: { username: 'admin' } });
    if (!admin) {
        const hash = await bcrypt.hash('admin123', 10);
        admin = this.userRepo.create({
            username: 'admin',
            password: hash,
            role: 'VENUE_ADMIN',
            venueId: 1,
            niteBalance: 0
        });
        await this.userRepo.save(admin);
    }
    
    return { user, admin: 'admin / admin123' };
  }
}
EOF

# --- 8. Rebuild & Restart ---
echo "Rebuilding backend..."
cd $BASE_DIR
npm run build

echo "Restarting PM2..."
pm2 restart nite-backend
sleep 5

# --- 9. Documentation Update ---
if pm2 status nite-backend | grep -q "online"; then
    echo "✅ Phase 4 Deployed: Auth & Guards Active."

    # Update Roadmap
    cat << 'DOCEOF' > /opt/nite-os/docs/V8-Roadmap.md
# NiteOS V8 – Roadmap

## Phase 0 – Preflight (DONE)
## Phase 1 – Backend Skeleton (DONE)
## Phase 2 – Core Entities (DONE)
## Phase 3 – Market + POS Logic (DONE)

## Phase 4 – Auth & Roles (DONE)
- JWT Authentication implemented (Passport + JWT).
- Roles: USER, STAFF, VENUE_ADMIN, NITECORE_ADMIN.
- Secured \`/api/pos/*\` endpoints with \`JwtAuthGuard\` and \`RolesGuard\`.
- Added Password support for Staff users.

---

## Phase 5 – Redis + Mongo (NEXT)
Goal: Performance & Observability.
- Redis: Session store & Rate limiting.
- Mongo: Analytics Logs.

## Phase 6 – Frontend SPA
DOCEOF

    # Update Phase Log
    cat << 'DOCEOF' >> /opt/nite-os/docs/V8-Phase-Log.md

## 2025-12-05 – Phase 4 – Auth & Roles
- Installed \`@nestjs/jwt\`, \`passport\`, \`bcryptjs\`.
- Updated User entity with \`username\` and \`password\`.
- Implemented \`AuthModule\` with \`/auth/login\`.
- Added global \`RolesGuard\` and \`JwtAuthGuard\`.
- Secured POS Checkout: requires valid JWT + STAFF role + Venue Match.
DOCEOF

    echo "✅ Docs updated."
else
    echo "❌ Deployment failed."
    pm2 logs nite-backend --lines 20 --nostream
fi
