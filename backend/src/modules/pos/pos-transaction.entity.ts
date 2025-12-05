import { Entity, Column, PrimaryGeneratedColumn, CreateDateColumn } from 'typeorm';

@Entity('pos_transactions')
export class PosTransaction {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  venueId: number;

  @Column()
  staffId: number; // User ID of staff member

  @Column({ nullable: true })
  userId: number; // User ID of customer (if known)

  @Column({ nullable: true })
  nitetapId: string; // Card ID presented

  @Column({ type: 'decimal', default: 0 })
  totalChf: number;

  @Column({ type: 'decimal', default: 0 })
  totalNite: number;

  @Column({ default: 'COMPLETED' })
  status: string;

  @CreateDateColumn()
  createdAt: Date;
}
