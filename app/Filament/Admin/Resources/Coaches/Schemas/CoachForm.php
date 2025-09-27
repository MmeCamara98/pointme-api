<?php

namespace App\Filament\Admin\Resources\Coaches\Schemas;

use Filament\Schemas\Schema;

use Filament\Forms;
use Filament\Forms\Form;

class CoachForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                //
                  Forms\Components\TextInput::make('first_name_coach')
                    ->label('Prénom Coach')
                    ->required()
                    ->maxLength(255),

                Forms\Components\TextInput::make('last_name')
                    ->label('Nom Coach')
                    ->required()
                    ->maxLength(255),

                Forms\Components\TextInput::make('email')
                    ->label('Adresse Email')
                    ->email()
                    ->unique(ignoreRecord: true) // éviter doublons
                    ->required(),

                Forms\Components\TextInput::make('password')
                    ->label('Mot de Passe')
                    ->password()
                    ->revealable()
                    ->required(),

                Forms\Components\TextInput::make('phone')
                    ->label('Numéro de téléphone')
                    ->required()
                    ->maxLength(255),

                Forms\Components\FileUpload::make('photo')
                    ->label('Photo de profile')
                    ->image()
                    ->directory('coaches/photos')
                    ->nullable(),
            ]);
    }
}
