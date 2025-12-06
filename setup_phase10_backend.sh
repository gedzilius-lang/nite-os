#!/bin/bash

BASE_DIR="/opt/nite-os/backend/src/modules"
RADIO_KEY="nite_radio_secret_key_999" # Simple secret for internal comms

echo "--- 🎵 PHASE 10: BACKEND RADIO MODULE ---"

# 1. Create Directory
mkdir -p $BASE_DIR/radio

# 2. Create Service (Stores data in Redis)
cat <<EOF > $BASE_DIR/radio/radio.service.ts
import { Injectable, Inject } from '@nestjs/common';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import { Cache } from 'cache-manager';

@Injectable()
export class RadioService {
  constructor(@Inject(CACHE_MANAGER) private cacheManager: Cache) {}

  async updateNowPlaying(meta: any) {
    // Store for 1 hour (or until next update)
    await this.cacheManager.set('radio:now_playing', meta, 3600000); 
    return { status: 'updated', meta };
  }

  async getNowPlaying() {
    const data = await this.cacheManager.get('radio:now_playing');
    return data || { artist: 'Nite Radio', title: 'Live Stream' };
  }
}
EOF

# 3. Create Controller (Endpoints)
cat <<EOF > $BASE_DIR/radio/radio.controller.ts
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
    if (secret !== '$RADIO_KEY') {
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
EOF

# 4. Create Module
cat <<EOF > $BASE_DIR/radio/radio.module.ts
import { Module } from '@nestjs/common';
import { RadioController } from './radio.controller';
import { RadioService } from './radio.service';

@Module({
  controllers: [RadioController],
  providers: [RadioService],
})
export class RadioModule {}
EOF

# 5. Register in App Module (Quick Patch)
# We use sed to insert the module import since we don't want to rewrite the whole file
APP_MOD="/opt/nite-os/backend/src/app.module.ts"
if ! grep -q "RadioModule" $APP_MOD; then
    echo "Registering RadioModule in app.module.ts..."
    # Add Import
    sed -i "/import { AnalyticsModule }/a import { RadioModule } from './modules/radio/radio.module';" $APP_MOD
    # Add to Imports Array
    sed -i "/AnalyticsModule,/a \    RadioModule," $APP_MOD
fi

# 6. Rebuild
echo "Rebuilding Backend..."
cd /opt/nite-os/backend
npm run build
pm2 restart nite-backend

echo "✅ Backend Radio Module Active."
