import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PosController } from './pos.controller';
import { PosService } from './pos.service';
import { PosTransaction } from './pos-transaction.entity';

// Import other modules to access their Repositories
import { UsersModule } from '../users/users.module';
import { MarketModule } from '../market/market.module';
import { NitecoinModule } from '../nitecoin/nitecoin.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([PosTransaction]),
    UsersModule,    // Access to UserRepository
    MarketModule,   // Access to MarketItemRepository
    NitecoinModule, // Access to NitecoinTransactionRepository
  ],
  controllers: [PosController],
  providers: [PosService],
})
export class PosModule {}
