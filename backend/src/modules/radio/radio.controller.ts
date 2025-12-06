import { Controller, Get, Post, Body, Query, UnauthorizedException } from '@nestjs/common';
import { RadioService } from './radio.service';

@Controller('radio')
export class RadioController {
  constructor(private readonly radioService: RadioService) {}

  // Public Endpoint for Frontend
  @Get('now-playing')
  async getNowPlaying() {
    return this.radioService.getNowPlaying();
  }

  // Private Webhook for Liquidsoap
  @Post('webhook')
  async webhook(@Body() body: any, @Query('secret') secret: string) {
    if (secret !== 'nite_radio_secret_key_999') {
      throw new UnauthorizedException('Invalid Radio Secret');
    }
    // Sanitize incoming Liquidsoap data
    const meta = {
      artist: body.artist || 'Unknown Artist',
      title: body.title || 'Unknown Track',
      timestamp: new Date().toISOString()
    };
    return this.radioService.updateNowPlaying(meta);
  }
}
