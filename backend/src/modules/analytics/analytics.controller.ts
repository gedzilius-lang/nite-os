import { Controller, Get, UseGuards } from '@nestjs/common';
import { AnalyticsService } from './analytics.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';

@Controller('analytics')
@UseGuards(JwtAuthGuard, RolesGuard)
export class AnalyticsController {
  constructor(private readonly service: AnalyticsService) {}

  @Get('health')
  health() {
    return this.service.getHealth();
  }

  @Get('logs')
  @Roles('NITECORE_ADMIN', 'VENUE_ADMIN')
  async getLogs() {
    return this.service.getRecentLogs();
  }
}
