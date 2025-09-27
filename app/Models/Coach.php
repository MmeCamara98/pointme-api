<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Support\Facades\Hash;
use Tymon\JWTAuth\Contracts\JWTSubject;

class Coach extends Authenticatable implements JWTSubject
{
    use HasFactory, Notifiable;

     protected $primaryKey = 'id'; 

        public $incrementing = true;        // si coach_id est AUTO_INCREMENT
    protected $keyType = 'int';         // type numérique
    protected $fillable = [
        'coach_id', 'first_name_coach', 'last_name', 'email', 'password', 'photo', 'phone',
    ];

    protected $hidden = [
        'password',
    ];

    // Mutator pour hasher le password automatiquement
    public function setPasswordAttribute($value)
    {
        if ($value) {
            $this->attributes['password'] = Hash::needsRehash($value) ? Hash::make($value) : $value;
        }
    }

    // Accessor full name
    public function getFullNameAttribute(): string
    {
        return trim("{$this->first_name_coach} {$this->last_name}");
    }

    public function stagiaires()
    {
        return $this->hasMany(Stagiaire::class);
    }

    // Méthodes requises par JWTSubject
    public function getJWTIdentifier()
    {
        return $this->getKey();
    }

    public function getJWTCustomClaims()
    {
        return [];
    }
}
