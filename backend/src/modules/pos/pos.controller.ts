import { Controller, Post, Body, Param, Get } from '@nestjs/common';
import { PosService, CheckoutDto } from './pos.service';

@Controller('pos')
export class PosController {
  constructor(private readonly service: PosService) {}

  @Post(':venueId/checkout')
  async checkout(
    @Param('venueId') venueId: string,
    @Body() dto: CheckoutDto
  ) {
    return this.service.checkout(Number(venueId), dto);
  }

  @Get('health')
  health() {
    return { status: 'ok', service: 'pos' };
  }
}
