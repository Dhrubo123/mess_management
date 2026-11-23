<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class MessMonth extends Model
{
    protected $fillable = [
        'mess_id',
        'year',
        'month',
        'manager_id',
        'status',
        'closed_at',
    ];

    protected function casts(): array
    {
        return [
            'year' => 'integer',
            'month' => 'integer',
            'closed_at' => 'datetime',
        ];
    }

    public function mess(): BelongsTo
    {
        return $this->belongsTo(Mess::class);
    }

    public function manager(): BelongsTo
    {
        return $this->belongsTo(User::class, 'manager_id');
    }

    public function meals(): HasMany
    {
        return $this->hasMany(Meal::class);
    }

    public function bazars(): HasMany
    {
        return $this->hasMany(Bazar::class);
    }

    public function deposits(): HasMany
    {
        return $this->hasMany(Deposit::class);
    }

    public function fixedBills(): HasMany
    {
        return $this->hasMany(FixedBill::class);
    }
}
