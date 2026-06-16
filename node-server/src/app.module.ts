import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import configuration from './config/configuration';
import { AppController } from './app.controller';
import { DbModule } from './db/db.module';
import { AuthModule } from './auth/auth.module';
import { UsageModule } from './usage/usage.module';
import { BillingModule } from './billing/billing.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true, load: [configuration] }),
    JwtModule.registerAsync({
      global: true,
      inject: [ConfigService],
      useFactory: (c: ConfigService) => ({
        secret: c.get<string>('jwt.secret'),
        signOptions: { expiresIn: c.get<string>('jwt.expiresIn') },
      }),
    }),
    DbModule.forRoot(),
    AuthModule,
    UsageModule,
    BillingModule,
  ],
  controllers: [AppController],
})
export class AppModule {}
