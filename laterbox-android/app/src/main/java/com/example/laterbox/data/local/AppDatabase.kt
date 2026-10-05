package com.example.laterbox.data.local

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase

@Database(
    entities = [ItemEntity::class, ItemMetadataEntity::class, CollectionEntity::class],
    version = 3,
    exportSchema = false
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun itemDao(): ItemDao
    abstract fun itemMetadataDao(): ItemMetadataDao
    abstract fun collectionDao(): CollectionDao

    companion object {
        @Volatile
        private var INSTANCE: AppDatabase? = null

        fun getDatabase(context: Context): AppDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "laterbox_database"
                )
                    .addMigrations(object : Migration(2, 3) {
                        override fun migrate(db: SupportSQLiteDatabase) {
                            listOf("tags", "category", "summary", "formattedContent", "notes").forEach {
                                db.execSQL("ALTER TABLE items ADD COLUMN $it TEXT NOT NULL DEFAULT ''")
                            }
                            db.execSQL("ALTER TABLE items ADD COLUMN collectionId TEXT")
                            db.execSQL("ALTER TABLE items ADD COLUMN attachments TEXT NOT NULL DEFAULT '[]'")
                        }
                    })
                    .build()
                INSTANCE = instance
                instance
            }
        }
    }
}
