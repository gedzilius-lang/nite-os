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
