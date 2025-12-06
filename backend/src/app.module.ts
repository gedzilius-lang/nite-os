import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MongooseModule } from '@nestjs/mongoose';
import { CacheModule } from '@nestjs/cache-manager';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { APP_GUARD } from '@nestjs/core';
import * as redisStore from 'cache-manager-ioredis';

// Modules
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
      entities: [User, Venue, MarketItem, NitecoinTransaction, PosTransaction],
      
      // PRODUCTION SAFETY:
      // We disable auto-sync to prevent schema data loss.
      // Future changes should use Migrations.
      synchronize: false, 
    }),

    MongooseModule.forRoot('mongodb://127.0.0.1:27017/nite_analytics'),

    CacheModule.register({
      isGlobal: true, 
      store: redisStore,
      host: '127.0.0.1',
      port: 6379,
    }),

    ThrottlerModule.forRoot([{
      ttl: 60000,
      limit: 100,
    }]),

    UsersModule,
    VenuesModule,
    NitecoinModule,
    MarketModule,
    PosModule,
    FeedModule,
    AuthModule,
    AnalyticsModule,
  ],
  providers: [
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    },
  ],
})
export class AppModule {}
