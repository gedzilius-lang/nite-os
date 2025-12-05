import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { NitecoinController } from './nitecoin.controller';
import { NitecoinService } from './nitecoin.service';
import { NitecoinTransaction } from './nitecoin-transaction.entity';

@Module({
  imports: [TypeOrmModule.forFeature([NitecoinTransaction])],
  controllers: [NitecoinController],
  providers: [NitecoinService],
  exports: [TypeOrmModule],
})
export class NitecoinModule {}
