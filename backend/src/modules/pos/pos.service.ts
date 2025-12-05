import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In } from 'typeorm';
import { PosTransaction } from './pos-transaction.entity';
import { User } from '../users/user.entity';
import { MarketItem } from '../market/market-item.entity';
import { NitecoinTransaction } from '../nitecoin/nitecoin-transaction.entity';

export interface CheckoutItemDto {
  itemId: number;
  count: number;
}

export interface CheckoutDto {
  nitetapId: string;
  items: CheckoutItemDto[];
  staffId: number; // In real app, this comes from JWT
}

@Injectable()
export class PosService {
  constructor(
    @InjectRepository(PosTransaction) private posRepo: Repository<PosTransaction>,
    @InjectRepository(User) private userRepo: Repository<User>,
    @InjectRepository(MarketItem) private itemRepo: Repository<MarketItem>,
    @InjectRepository(NitecoinTransaction) private nitecoinRepo: Repository<NitecoinTransaction>,
  ) {}

  async checkout(venueId: number, dto: CheckoutDto) {
    // 1. Find User
    const user = await this.userRepo.findOne({ where: { nitetapId: dto.nitetapId } });
    if (!user) {
      throw new NotFoundException('NiteTap ID not found');
    }

    // 2. Fetch Items
    const itemIds = dto.items.map((i) => i.itemId);
    const dbItems = await this.itemRepo.find({ where: { id: In(itemIds) } });
    
    // 3. Calculate Totals
    let totalChf = 0;
    let totalNite = 0;

    for (const reqItem of dto.items) {
      const dbItem = dbItems.find((i) => i.id === reqItem.itemId);
      if (!dbItem) continue; // Skip invalid IDs
      totalChf += Number(dbItem.priceChf) * reqItem.count;
      totalNite += Number(dbItem.priceNite) * reqItem.count;
    }

    if (totalNite === 0 && totalChf === 0) {
      throw new BadRequestException('No valid items found');
    }

    // 4. Check Balance
    if (user.niteBalance < totalNite) {
      throw new BadRequestException(`Insufficient Nitecoin. Required: ${totalNite}, Has: ${user.niteBalance}`);
    }

    // 5. Execute Transaction (Deduct Balance)
    user.niteBalance = Number(user.niteBalance) - totalNite;
    await this.userRepo.save(user);

    // 6. Log Nitecoin Spend
    if (totalNite > 0) {
      await this.nitecoinRepo.save({
        userId: user.id,
        venueId: venueId,
        amount: -totalNite,
        type: 'SPEND'
      });
    }

    // 7. Create POS Receipt
    const receipt = await this.posRepo.save({
      venueId: venueId,
      staffId: dto.staffId,
      userId: user.id,
      nitetapId: dto.nitetapId,
      totalChf: totalChf,
      totalNite: totalNite,
      status: 'COMPLETED'
    });

    return {
      success: true,
      newBalance: user.niteBalance,
      receiptId: receipt.id,
      totalNitePaid: totalNite
    };
  }
}
