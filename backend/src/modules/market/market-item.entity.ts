import { Entity, Column, PrimaryGeneratedColumn, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('market_items')
export class MarketItem {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  venueId: number; // FK to Venue

  @Column()
  title: string;

  @Column({ type: 'decimal' })
  priceChf: number;

  @Column({ type: 'decimal' })
  priceNite: number;

  @Column({ default: true })
  active: boolean;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
