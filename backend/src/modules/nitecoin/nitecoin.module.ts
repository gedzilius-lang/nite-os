import { Module } from '@nestjs/common';
import { NitecoinController } from './nitecoin.controller';
import { NitecoinService } from './nitecoin.service';

@Module({
  controllers: [NitecoinController],
  providers: [NitecoinService],
})
export class NitecoinModule {}
