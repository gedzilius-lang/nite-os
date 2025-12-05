import { Controller, Get } from '@nestjs/common';
import { VenuesService } from './venues.service';

@Controller('venues')
export class VenuesController {
  constructor(private readonly service: VenuesService) {}

  @Get('health')
  healthCheck() {
    return this.service.getHealth();
  }
}
