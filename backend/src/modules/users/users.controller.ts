import { Controller, Get, Post } from '@nestjs/common';
import { UsersService } from './users.service';

@Controller('users')
export class UsersController {
  constructor(private readonly service: UsersService) {}

  @Get('health')
  healthCheck() {
    return this.service.getHealth();
  }

  @Post('demo')
  async createDemo() {
    return this.service.createDemoUser();
  }
}
