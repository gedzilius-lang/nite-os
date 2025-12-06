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
