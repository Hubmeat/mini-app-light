import { DynamicModule, Global, Logger, Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { STORE, Store } from './store.interface';
import { createMemoryStore } from './adapters/memory.adapter';
import { createPgStore } from './adapters/pg.adapter';
import { createMysqlStore } from './adapters/mysql.adapter';
import { createSupabaseStore } from './adapters/supabase.adapter';

/** 全局数据模块：按 DB_DRIVER 选择适配器，提供 STORE。 */
@Global()
@Module({})
export class DbModule {
  static forRoot(): DynamicModule {
    return {
      module: DbModule,
      providers: [
        {
          provide: STORE,
          inject: [ConfigService],
          useFactory: (config: ConfigService): Store => {
            const driver = config.get<string>('db.driver') || 'memory';
            let store: Store;
            switch (driver) {
              case 'postgres':
              case 'pg':
                store = createPgStore(config);
                break;
              case 'mysql':
                store = createMysqlStore(config);
                break;
              case 'supabase':
                store = createSupabaseStore(config);
                break;
              default:
                store = createMemoryStore(
                  config.get<number>('usage.freeQuota') ?? 20,
                );
            }
            new Logger('Db').log(`使用存储适配器: ${store.driver}`);
            return store;
          },
        },
      ],
      exports: [STORE],
    };
  }
}
