<?php

namespace App\Filament\Admin\Resources\Stagiaires\Schemas;

use Filament\Forms\Components\DatePicker;
use Filament\Forms\Components\TextInput;
use Filament\Schemas\Schema;
 use Filament\Forms\Components\Select;

class StagiaireForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Select::make('first_name_coach')
                ->label('Nom Coach')->placeholder('Sélectionner le coach')
                ->relationship(name: 'coach', titleAttribute: 'first_name_coach')
                ->searchable()
                ->loadingMessage('Recherche votre coach...'),
                TextInput::make('first_name')
                ->label('Prénom Stagiaire')
                    ->required(),
                TextInput::make('last_name')
                ->label('Nom Stagiaire')
                    ->required(),
                TextInput::make('email')
                    ->label('Address email')
                    ->email()
                    ->default(null),
                TextInput::make('phone')
                    ->label('Téléphone')
                    ->tel()
                    ->default(null),
                TextInput::make('promotion')
                    ->label('Promotion')
                    ->default(null),
                DatePicker::make('start_date')
                    ->label('Date de début'),
                DatePicker::make('end_date')
                    ->label('Date de fin'),
            ]);
    }
}
