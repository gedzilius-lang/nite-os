import { Repository } from 'typeorm';
import { PosTransaction } from './pos-transaction.entity';
import { User } from '../users/user.entity';
import { MarketItem } from '../market/market-item.entity';
import { NitecoinTransaction } from '../nitecoin/nitecoin-transaction.entity';
import { AnalyticsService } from '../analytics/analytics.service';
export interface CheckoutItemDto {
    itemId: number;
    count: number;
}
export interface CheckoutDto {
    nitetapId: string;
    items: CheckoutItemDto[];
}
export declare class PosService {
    private posRepo;
    private userRepo;
    private itemRepo;
    private nitecoinRepo;
    private analytics;
    constructor(posRepo: Repository<PosTransaction>, userRepo: Repository<User>, itemRepo: Repository<MarketItem>, nitecoinRepo: Repository<NitecoinTransaction>, analytics: AnalyticsService);
    checkout(venueId: number, dto: CheckoutDto, staffUser: any): Promise<{
        success: boolean;
        newBalance: number;
        receiptId: number;
    }>;
}
