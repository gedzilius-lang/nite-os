#!/bin/bash

# Define base path
BASE_DIR="/opt/nite-os/backend"
mkdir -p $BASE_DIR

# --- 1. package.json ---
cat <<EOF > $BASE_DIR/package.json
{
  "name": "nite-backend",
  "version": "0.0.1",
  "description": "NiteOS V8 Backend",
  "author": "NiteCore",
  "private": true,
  "license": "UNLICENSED",
  "scripts": {
    "build": "nest build",
    "format": "prettier --write \"src/**/*.ts\"",
    "start": "node dist/main",
    "start:dev": "nest start --watch",
    "start:debug": "nest start --debug --watch",
    "start:prod": "node dist/main",
    "lint": "eslint \"{src,apps,libs,test}/**/*.ts\" --fix"
  },
  "dependencies": {
    "@nestjs/common": "^10.0.0",
    "@nestjs/core": "^10.0.0",
    "@nestjs/platform-express": "^10.0.0",
    "@nestjs/typeorm": "^10.0.0",
    "pg": "^8.11.0",
    "reflect-metadata": "^0.1.13",
    "rxjs": "^7.8.1",
    "typeorm": "^0.3.17",
    "class-validator": "^0.14.0",
    "class-transformer": "^0.5.1"
  },
  "devDependencies": {
    "@nestjs/cli": "^10.0.0",
    "@nestjs/schematics": "^10.0.0",
    "@nestjs/testing": "^10.0.0",
    "@types/express": "^4.17.17",
    "@types/node": "^20.3.1",
    "@typescript-eslint/eslint-plugin": "^6.0.0",
    "@typescript-eslint/parser": "^6.0.0",
    "eslint": "^8.42.0",
    "prettier": "^3.0.0",
    "source-map-support": "^0.5.21",
    "ts-loader": "^9.4.3",
    "ts-node": "^10.9.1",
    "tsconfig-paths": "^4.2.0",
    "typescript": "^5.1.3"
  }
}
EOF

# --- 2. tsconfig.json ---
cat <<EOF > $BASE_DIR/tsconfig.json
{
  "compilerOptions": {
    "module": "commonjs",
    "declaration": true,
    "removeComments": true,
    "emitDecoratorMetadata": true,
    "experimentalDecorators": true,
    "allowSyntheticDefaultImports": true,
    "target": "es2017",
    "sourceMap": true,
    "outDir": "./dist",
    "baseUrl": "./",
    "incremental": true,
    "skipLibCheck": true,
    "strictNullChecks": false,
    "noImplicitAny": false,
    "strictBindCallApply": false,
    "forceConsistentCasingInFileNames": false,
    "noFallthroughCasesInSwitch": false
  }
}
EOF

# --- 3. Source Structure ---
mkdir -p $BASE_DIR/src/modules/users
mkdir -p $BASE_DIR/src/modules/venues
mkdir -p $BASE_DIR/src/modules/nitecoin
mkdir -p $BASE_DIR/src/modules/market
mkdir -p $BASE_DIR/src/modules/pos
mkdir -p $BASE_DIR/src/modules/feed
mkdir -p $BASE_DIR/src/modules/auth
mkdir -p $BASE_DIR/src/modules/analytics

# --- 4. Main Entry (src/main.ts) ---
cat <<EOF > $BASE_DIR/src/main.ts
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  
  // Global Prefix
  app.setGlobalPrefix('api');
  
  // CORS enabled
  app.enableCors();

  await app.listen(3000);
  console.log('NiteOS Backend running on port 3000');
}
bootstrap();
EOF

# --- 5. App Module (src/app.module.ts) ---
cat <<EOF > $BASE_DIR/src/app.module.ts
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UsersModule } from './modules/users/users.module';
import { VenuesModule } from './modules/venues/venues.module';
import { NitecoinModule } from './modules/nitecoin/nitecoin.module';
import { MarketModule } from './modules/market/market.module';
import { PosModule } from './modules/pos/pos.module';
import { FeedModule } from './modules/feed/feed.module';
import { AuthModule } from './modules/auth/auth.module';
import { AnalyticsModule } from './modules/analytics/analytics.module';
import { User } from './modules/users/user.entity';

@Module({
  imports: [
    TypeOrmModule.forRoot({
      type: 'postgres',
      host: 'localhost',
      port: 5432,
      username: 'nite',
      password: 'nitepassword',
      database: 'nite_os',
      entities: [User], // Explicitly listing User for now, others will be added later
      synchronize: true, // DEV ONLY
    }),
    UsersModule,
    VenuesModule,
    NitecoinModule,
    MarketModule,
    PosModule,
    FeedModule,
    AuthModule,
    AnalyticsModule,
  ],
})
export class AppModule {}
EOF

# --- 6. User Entity (src/modules/users/user.entity.ts) ---
cat <<EOF > $BASE_DIR/src/modules/users/user.entity.ts
import { Entity, Column, PrimaryGeneratedColumn, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ nullable: true })
  externalId: string; // For potential external auth links

  @Column({ unique: true, nullable: true })
  nitetapId: string; // The physical card/chip ID

  @Column({ default: 0 })
  xp: number;

  @Column({ default: 1 })
  level: number;

  @Column({ default: 0 })
  niteBalance: number;

  @Column({ default: 'USER' })
  role: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
EOF

# --- 7. Generate Module Stubs ---
# Function to generate basic module files
generate_module() {
  local MOD=\$1
  local CLASS=\$(echo "\$MOD" | awk '{print toupper(substr(\$0,1,1)) substr(\$0,2)}')

  # Controller
  cat <<EOF > $BASE_DIR/src/modules/\$MOD/\$MOD.controller.ts
import { Controller, Get } from '@nestjs/common';
import { \${CLASS}Service } from './\$MOD.service';

@Controller('\$MOD')
export class \${CLASS}Controller {
  constructor(private readonly service: \${CLASS}Service) {}

  @Get('health')
  healthCheck() {
    return this.service.getHealth();
  }
}
EOF

  # Service
  cat <<EOF > $BASE_DIR/src/modules/\$MOD/\$MOD.service.ts
import { Injectable } from '@nestjs/common';

@Injectable()
export class \${CLASS}Service {
  getHealth() {
    return { status: 'ok', service: '$MOD', timestamp: new Date().toISOString() };
  }
}
EOF

  # Module
  cat <<EOF > $BASE_DIR/src/modules/\$MOD/\$MOD.module.ts
import { Module } from '@nestjs/common';
import { \${CLASS}Controller } from './\$MOD.controller';
import { \${CLASS}Service } from './\$MOD.service';

@Module({
  controllers: [\${CLASS}Controller],
  providers: [\${CLASS}Service],
})
export class \${CLASS}Module {}
EOF
}

# Generate stubs for all modules
generate_module "users"
generate_module "venues"
generate_module "nitecoin"
generate_module "market"
generate_module "pos"
generate_module "feed"
generate_module "auth"
generate_module "analytics"

# Need to manually update UsersModule to import TypeOrmModule for the entity later, 
# but for Phase 1 skeleton, the generic stub is fine. 
# We will just verify TypeORM connects via AppModule.

echo "File structure created in /opt/nite-os/backend"
EOF
