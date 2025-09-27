<?php

namespace App\Filament\Admin\Resources\Coaches;

use App\Filament\Admin\Resources\Coaches\Pages\CreateCoach;
use App\Filament\Admin\Resources\Coaches\Pages\EditCoach;
use App\Filament\Admin\Resources\Coaches\Pages\ListCoaches;
use App\Filament\Admin\Resources\Coaches\Schemas\CoachForm;
use App\Filament\Admin\Resources\Coaches\Tables\CoachesTable;
use App\Models\Coach;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;
use Filament\Tables\Columns\ImageColumn;

class CoachResource extends Resource
{
    protected static ?string $model = Coach::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedRectangleStack;

    protected static ?string $recordTitleAttribute = 'Inscription Coach';

    public static function form(Schema $schema): Schema
    {
        return CoachForm::configure($schema);
    }

    public static function table(Table $table): Table
    {
        return $table->columns([
        // CoachesTable::configure($table);

                    // Ici tu choisis les colonnes à afficher
            ImageColumn::make('photo')->label('Photo')->circular()->size(50),
            \Filament\Tables\Columns\TextColumn::make('first_name_coach')->label('Prénom')->searchable(),
            \Filament\Tables\Columns\TextColumn::make('last_name')->label('Nom')->searchable(),
            \Filament\Tables\Columns\TextColumn::make('email')->label('Email'),
            \Filament\Tables\Columns\TextColumn::make('phone')->label('Téléphone'),
        ]);
    }

    public static function getRelations(): array
    {
        return [
            //
        ];
    }

    public static function getPages(): array
    {
        return [
            'index' => ListCoaches::route('/'),
            'create' => CreateCoach::route('/create'),
            'edit' => EditCoach::route('/{record}/edit'),
        ];
    }
}
