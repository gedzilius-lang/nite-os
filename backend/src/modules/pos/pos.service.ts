import { Injectable, BadRequestException, NotFoundException, ForbiddenException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In } from 'typeorm';
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

@Injectable()
export class PosService {
  constructor(
    @InjectRepository(PosTransaction) private posRepo: Repository<PosTransaction>,
    @InjectRepository(User) private userRepo: Repository<User>,
    @InjectRepository(MarketItem) private itemRepo: Repository<MarketItem>,
    @InjectRepository(NitecoinTransaction) private nitecoinRepo: Repository<NitecoinTransaction>,
    private analytics: AnalyticsService,
  ) {}

  async checkout(venueId: number, dto: CheckoutDto, staffUser: any) {
    // Security Check
    if (staffUser.role !== 'NITECORE_ADMIN' && staffUser.venueId !== venueId) {
       throw new ForbiddenException('You are not authorized for this venue');
    }

    // 1. Find Customer
    const customer = await this.userRepo.findOne({ where: { nitetapId: dto.nitetapId } });
    if (!customer) throw new NotFoundException('NiteTap ID not found');

    // 2. Fetch Items
    const itemIds = dto.items.map((i) => i.itemId);
    const dbItems = await this.itemRepo.find({ where: { id: In(itemIds) } });
    
    // 3. Calc Totals
    let totalChf = 0;
    let totalNite = 0;

    for (const reqItem of dto.items) {
      const dbItem = dbItems.find((i) => i.id === reqItem.itemId);
      if (!dbItem) continue;
      totalChf += Number(dbItem.priceChf) * reqItem.count;
      totalNite += Number(dbItem.priceNite) * reqItem.count;
    }

    if (totalNite === 0 && totalChf === 0) throw new BadRequestException('No valid items');
    if (customer.niteBalance < totalNite) throw new BadRequestException(`Insufficient Nitecoin`);

    // 4. Execute
    customer.niteBalance = Number(customer.niteBalance) - totalNite;
    await this.userRepo.save(customer);

    if (totalNite > 0) {
      await this.nitecoinRepo.save({
        userId: customer.id,
        venueId: venueId,
        amount: -totalNite,
        type: 'SPEND'
      });
    }

    const receipt = await this.posRepo.save({
      venueId: venueId,
      staffId: staffUser.userId,
      userId: customer.id,
      nitetapId: dto.nitetapId,
      totalChf: totalChf,
      totalNite: totalNite,
      status: 'COMPLETED'
    });

    // 5. ASYNC ANALYTICS LOG (Fire & Forget)
    this.analytics.logEvent('POS', 'CHECKOUT', customer.id, {
        venueId,
        totalNite,
        receiptId: receipt.id
    });

    return {
      success: true,
      newBalance: customer.niteBalance,
      receiptId: receipt.id
    };
  }
}
