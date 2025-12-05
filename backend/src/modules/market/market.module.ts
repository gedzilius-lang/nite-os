import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MarketController } from './market.controller';
import { MarketService } from './market.service';
import { MarketItem } from './market-item.entity';

@Module({
  imports: [TypeOrmModule.forFeature([MarketItem])],
  controllers: [MarketController],
  providers: [MarketService],
  exports: [TypeOrmModule],
})
export class MarketModule {}
