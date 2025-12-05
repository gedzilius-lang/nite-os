import { Controller, Get } from '@nestjs/common';
import { NitecoinService } from './nitecoin.service';

@Controller('nitecoin')
export class NitecoinController {
  constructor(private readonly service: NitecoinService) {}

  @Get('health')
  healthCheck() {
    return this.service.getHealth();
  }
}
