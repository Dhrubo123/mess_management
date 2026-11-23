<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->boolean('is_admin')->default(false)->after('locale');
        });

        Schema::create('sponsor_banners', function (Blueprint $table) {
            $table->id();
            $table->string('sponsor_name', 100);
            $table->string('headline', 140);
            $table->string('subtitle', 220)->nullable();
            $table->string('cta_label', 40)->default('Call Now');
            $table->string('cta_value', 120); // phone number or URL
            $table->string('target_area', 80)->nullable(); // null = All Chattogram
            $table->string('badge_text', 30)->default('SPONSORED');
            $table->boolean('is_active')->default(true);
            $table->unsignedInteger('clicks')->default(0);
            $table->timestamps();
        });

        Schema::create('boost_requests', function (Blueprint $table) {
            $table->id();
            $table->foreignId('seat_listing_id')->constrained('seat_listings')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->decimal('amount', 10, 2)->default(99);
            $table->string('payment_method', 20)->default('bkash'); // bkash, nagad
            $table->string('sender_phone', 20);
            $table->string('trx_id', 60);
            $table->unsignedTinyInteger('duration_days')->default(7);
            $table->string('status', 20)->default('pending'); // pending, approved, rejected
            $table->timestamp('reviewed_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('boost_requests');
        Schema::dropIfExists('sponsor_banners');

        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('is_admin');
        });
    }
};
