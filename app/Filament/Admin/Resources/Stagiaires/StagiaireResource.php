<?php

namespace App\Filament\Admin\Resources\Stagiaires;

use App\Filament\Admin\Resources\Stagiaires\Pages\CreateStagiaire;
use App\Filament\Admin\Resources\Stagiaires\Pages\EditStagiaire;
use App\Filament\Admin\Resources\Stagiaires\Pages\ListStagiaires;
use App\Filament\Admin\Resources\Stagiaires\Schemas\StagiaireForm;
use App\Filament\Admin\Resources\Stagiaires\Tables\StagiairesTable;
use App\Models\Stagiaire;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;

class StagiaireResource extends Resource
{
    protected static ?string $model = Stagiaire::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedRectangleStack;

    protected static ?string $recordTitleAttribute = 'Stagiare';

    public static function form(Schema $schema): Schema
    {
        return StagiaireForm::configure($schema);
    }

    public static function table(Table $table): Table
    {
        return StagiairesTable::configure($table);
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
            'index' => ListStagiaires::route('/'),
            'create' => CreateStagiaire::route('/create'),
            'edit' => EditStagiaire::route('/{record}/edit'),
        ];
    }
}
