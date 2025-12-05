import { Controller, Get } from '@nestjs/common';
import { PosService } from './pos.service';

@Controller('pos')
export class PosController {
  constructor(private readonly service: PosService) {}

  @Get('health')
  healthCheck() {
    return this.service.getHealth();
  }
}
