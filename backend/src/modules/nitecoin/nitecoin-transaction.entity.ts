import { Entity, Column, PrimaryGeneratedColumn, CreateDateColumn } from 'typeorm';

@Entity('nitecoin_transactions')
export class NitecoinTransaction {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  userId: number; // Who spent/earned

  @Column({ nullable: true })
  venueId: number; // Where it happened

  @Column({ type: 'decimal' })
  amount: number; // Positive = earn, Negative = spend

  @Column()
  type: string; // 'EARN', 'SPEND', 'ADJUSTMENT'

  @CreateDateColumn()
  createdAt: Date;
}
