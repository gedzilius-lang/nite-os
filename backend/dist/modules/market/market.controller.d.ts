import { MarketService } from './market.service';
export declare class MarketController {
    private readonly service;
    constructor(service: MarketService);
    healthCheck(): {
        status: string;
        service: string;
        timestamp: string;
    };
}
