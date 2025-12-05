import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './user.entity';

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
    // Create or reset a demo user
    let user = await this.userRepo.findOne({ where: { nitetapId: 'TAP-TEST' } });
    if (!user) {
        user = this.userRepo.create({
            nitetapId: 'TAP-TEST',
            niteBalance: 1000, 
            xp: 100,
            level: 5,
            role: 'USER'
        });
    } else {
        user.niteBalance = 1000; // Reset balance
    }
    return this.userRepo.save(user);
  }
}
