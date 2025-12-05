import { FeedService } from './feed.service';
export declare class FeedController {
    private readonly service;
    constructor(service: FeedService);
    healthCheck(): {
        status: string;
        service: string;
        timestamp: string;
    };
}
