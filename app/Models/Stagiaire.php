<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Support\Facades\Hash;
use Tymon\JWTAuth\Contracts\JWTSubject;

class Stagiaire extends Authenticatable implements JWTSubject
{
    use HasFactory, Notifiable;

    protected $primaryKey = 'id';
    public $incrementing = true;
    protected $keyType = 'int';

    protected $fillable = [
        'coach_id', 'first_name', 'last_name', 'email', 'phone', 'promotion', 'start_date', 'end_date', 'password',
    ];
    
    protected $hidden = [
        'password',
    ];

    public function coach()
    {  
        //        modèle lié , clé étrangère dans stagiaires , clé primaire dans coaches
    return $this->belongsTo(Coach::class, 'coach_id', 'id');
    
    }

    public function getFullNameAttribute(): string
    {
        return trim("{$this->first_name} {$this->last_name}");
    }
    
    // Mutator pour hasher le password automatiquement
    public function setPasswordAttribute($value)
    {
        if ($value) {
            $this->attributes['password'] = Hash::needsRehash($value) ? Hash::make($value) : $value;
        }
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