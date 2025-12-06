import { Cache } from 'cache-manager';
export declare class RadioService {
    private cacheManager;
    constructor(cacheManager: Cache);
    updateNowPlaying(meta: any): Promise<{
        status: string;
        meta: any;
    }>;
    getNowPlaying(): Promise<unknown>;
}
