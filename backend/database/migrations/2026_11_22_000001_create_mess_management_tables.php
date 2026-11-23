<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('phone', 20)->nullable()->unique()->after('email');
            $table->string('locale', 5)->default('en')->after('phone');
        });

        Schema::create('messes', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('invite_code', 10)->unique();
            $table->string('city', 60)->default('Dhaka');
            $table->string('area', 100);
            $table->string('address')->nullable();
            $table->string('meal_cutoff_time', 5)->default('22:00');
            $table->decimal('default_breakfast', 3, 1)->default(1.0);
            $table->decimal('default_lunch', 3, 1)->default(1.0);
            $table->decimal('default_dinner', 3, 1)->default(1.0);
            $table->boolean('is_pro')->default(false);
            $table->timestamp('pro_expires_at')->nullable();
            $table->foreignId('created_by')->constrained('users')->cascadeOnDelete();
            $table->timestamps();
        });

        Schema::create('mess_members', function (Blueprint $table) {
            $table->id();
            $table->foreignId('mess_id')->constrained('messes')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->string('role', 20)->default('member'); // manager, member
            $table->string('room_label', 60)->nullable();
            $table->decimal('monthly_seat_rent', 10, 2)->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamp('joined_at')->useCurrent();
            $table->timestamp('left_at')->nullable();
            $table->timestamps();

            $table->unique(['mess_id', 'user_id']);
        });

        Schema::create('mess_months', function (Blueprint $table) {
            $table->id();
            $table->foreignId('mess_id')->constrained('messes')->cascadeOnDelete();
            $table->unsignedSmallInteger('year');
            $table->unsignedTinyInteger('month');
            $table->foreignId('manager_id')->constrained('users')->cascadeOnDelete();
            $table->string('status', 20)->default('open'); // open, closed
            $table->timestamp('closed_at')->nullable();
            $table->timestamps();

            $table->unique(['mess_id', 'year', 'month']);
        });

        Schema::create('meals', function (Blueprint $table) {
            $table->id();
            $table->foreignId('mess_month_id')->constrained('mess_months')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->date('meal_date');
            $table->decimal('breakfast', 3, 1)->default(0);
            $table->decimal('lunch', 3, 1)->default(0);
            $table->decimal('dinner', 3, 1)->default(0);
            $table->decimal('guest_meals', 3, 1)->default(0);
            $table->foreignId('updated_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();

            $table->unique(['mess_month_id', 'user_id', 'meal_date']);
        });

        Schema::create('bazars', function (Blueprint $table) {
            $table->id();
            $table->foreignId('mess_month_id')->constrained('mess_months')->cascadeOnDelete();
            $table->foreignId('bought_by')->constrained('users')->cascadeOnDelete();
            $table->date('bazar_date');
            $table->decimal('amount', 10, 2);
            $table->text('items_note')->nullable();
            $table->string('receipt_path')->nullable();
            $table->foreignId('created_by')->constrained('users')->cascadeOnDelete();
            $table->timestamps();
        });

        Schema::create('deposits', function (Blueprint $table) {
            $table->id();
            $table->foreignId('mess_month_id')->constrained('mess_months')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->decimal('amount', 10, 2);
            $table->string('deposit_type', 20)->default('meal'); // meal, fixed_bill
            $table->string('payment_method', 20)->default('cash'); // cash, bkash, nagad, bank
            $table->string('reference', 100)->nullable();
            $table->date('deposit_date');
            $table->foreignId('recorded_by')->constrained('users')->cascadeOnDelete();
            $table->timestamps();
        });

        Schema::create('fixed_bills', function (Blueprint $table) {
            $table->id();
            $table->foreignId('mess_month_id')->constrained('mess_months')->cascadeOnDelete();
            $table->string('title', 100);
            $table->string('category', 30)->default('other'); // rent, wifi, bua, gas, electricity, water, other
            $table->decimal('total_amount', 10, 2);
            $table->string('split_type', 20)->default('equal');
            $table->string('notes')->nullable();
            $table->foreignId('created_by')->constrained('users')->cascadeOnDelete();
            $table->timestamps();
        });

        Schema::create('seat_listings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('mess_id')->nullable()->constrained('messes')->nullOnDelete();
            $table->foreignId('posted_by')->constrained('users')->cascadeOnDelete();
            $table->string('title', 140);
            $table->string('city', 60)->default('Dhaka');
            $table->string('area', 100);
            $table->string('address_hint', 180)->nullable();
            $table->string('seat_type', 30)->default('shared_seat'); // single_room, shared_seat, sublet
            $table->string('gender_preference', 15)->default('male'); // male, female
            $table->unsignedTinyInteger('seats_available')->default(1);
            $table->decimal('monthly_rent', 10, 2);
            $table->decimal('avg_meal_cost', 10, 2)->nullable();
            $table->date('available_from');
            $table->json('facilities')->nullable();
            $table->string('contact_phone', 20);
            $table->text('description')->nullable();
            $table->boolean('is_featured')->default(false);
            $table->timestamp('featured_until')->nullable();
            $table->string('status', 20)->default('active'); // active, filled, archived
            $table->timestamps();

            $table->index(['city', 'area', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('seat_listings');
        Schema::dropIfExists('fixed_bills');
        Schema::dropIfExists('deposits');
        Schema::dropIfExists('bazars');
        Schema::dropIfExists('meals');
        Schema::dropIfExists('mess_months');
        Schema::dropIfExists('mess_members');
        Schema::dropIfExists('messes');

        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['phone', 'locale']);
        });
    }
};
