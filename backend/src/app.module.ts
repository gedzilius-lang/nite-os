import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UsersModule } from './modules/users/users.module';
import { VenuesModule } from './modules/venues/venues.module';
import { NitecoinModule } from './modules/nitecoin/nitecoin.module';
import { MarketModule } from './modules/market/market.module';
import { PosModule } from './modules/pos/pos.module';
import { FeedModule } from './modules/feed/feed.module';
import { AuthModule } from './modules/auth/auth.module';
import { AnalyticsModule } from './modules/analytics/analytics.module';

// Entities
import { User } from './modules/users/user.entity';
import { Venue } from './modules/venues/venue.entity';
import { MarketItem } from './modules/market/market-item.entity';
import { NitecoinTransaction } from './modules/nitecoin/nitecoin-transaction.entity';
import { PosTransaction } from './modules/pos/pos-transaction.entity';

@Module({
  imports: [
    TypeOrmModule.forRoot({
      type: 'postgres',
      host: '127.0.0.1',
      port: 5432,
      username: 'nite',
      password: 'nitepassword',
      database: 'nite_os',
      entities: [
        User, 
        Venue, 
        MarketItem, 
        NitecoinTransaction, 
        PosTransaction
      ],
      synchronize: true, // Auto-creates tables
    }),
    UsersModule,
    VenuesModule,
    NitecoinModule,
    MarketModule,
    PosModule,
    FeedModule,
    AuthModule,
    AnalyticsModule,
  ],
})
export class AppModule {}
