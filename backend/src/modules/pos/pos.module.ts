import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PosController } from './pos.controller';
import { PosService } from './pos.service';
import { PosTransaction } from './pos-transaction.entity';

@Module({
  imports: [TypeOrmModule.forFeature([PosTransaction])],
  controllers: [PosController],
  providers: [PosService],
  exports: [TypeOrmModule],
})
export class PosModule {}
