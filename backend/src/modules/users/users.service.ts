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
