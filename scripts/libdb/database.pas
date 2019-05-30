unit database;

interface
    uses libdb;

    function DatabaseOpen(Database: LongInt; DatabaseName, User, Password: WideString; Plugin: TDatabasePluginType): Boolean;
    function DatabaseQuery(Database: LongInt; Query: WideString): Boolean;
    function DatabaseUpdate(Database: LongInt; Query: WideString): Boolean;
    procedure DatabasePrintValues(Database: LongInt);

implementation
    var
        DatabaseID: Integer;
        // PluginInitialized: Array[Ord(Low(TDatabasePluginType)))..Ord(High(TDatabasePluginType)))] of Boolean;
        // whatever...
        PluginInitialized: Array[0..4] of Boolean;

    function DatabaseOpen(Database: LongInt; DatabaseName, User, Password: WideString; Plugin: TDatabasePluginType): Boolean;
    var
        ReturnID: LongInt;
    begin
        case Plugin of
        DB_Plugin_ODBC:
            if Not PluginInitialized[Ord(Plugin)] then begin
                if Not DB_UseODBC then
                    RaiseException(erCustomError, 'ODBC environment could not be initialized.')
                else begin
                    {$IFDEF DEBUG}
                    WriteLn('ODBC environment has been initialized.');
                    {$ENDIF}
                    PluginInitialized[Ord(Plugin)] := True;
                end;
            end;

        DB_Plugin_MySQL:
            if Not PluginInitialized[Ord(Plugin)] then begin
                {$IFDEF WIN32}
                DB_UseMySQL('libmariadb.dll');
                {$ELSE}
                DB_UseMySQL('libmariadb.so');
                {$ENDIF}

                {$IFDEF DEBUG}
                WriteLn('MySQL environment has been initialized.');
                {$ENDIF}
                PluginInitialized[Ord(Plugin)] := True;
            end;

        DB_Plugin_PostgreSQL:
            if Not PluginInitialized[Ord(Plugin)] then begin
                DB_UsePostgreSQL;
                {$IFDEF DEBUG}
                WriteLn('PostgreSQL environment has been initialized.');
                {$ENDIF}
                PluginInitialized[Ord(Plugin)] := True;
            end;

        DB_Plugin_SQLite:
            if Not PluginInitialized[Ord(Plugin)] then begin
                DB_UseSQLite;
                {$IFDEF DEBUG}
                WriteLn('SQLite environment has been initialized.');
                {$ENDIF}
                PluginInitialized[Ord(Plugin)] := True;
            end;

        else
            begin
                {$IFDEF DEBUG}
                WriteLn('ERROR: Undefined plugin.');
                {$ENDIF}
            end;
        end;

        ReturnID := DB_Open(Database, DatabaseName, User, Password, Plugin);

        if ReturnID = 0 then begin
            {$IFDEF DEBUG}
            WriteLn('ERROR: Could not open a database. '+DB_Error);
            {$ENDIF}
            Result := False;
        end else begin
            if Database = DB_Any then DatabaseID := ReturnID;
            {$IFDEF DEBUG}
            WriteLn('DatabaseID: '+IntToStr(DatabaseID));
            {$ENDIF}

            Result := True;
        end;

    end;

    function DatabaseQuery(Database: LongInt; Query: WideString): Boolean;
    begin
        {$IFDEF DEBUG}
        WriteLn('> '+Query);
        {$ENDIF}

        if Not DB_IsDatabase(Database) then begin
            {$IFDEF DEBUG}
            WriteLn('ERROR: Wrong database ID provided.');
            {$ENDIF}
            Result := False; Exit;
        end;

        if Not DB_Query(Database, Query) then begin
            {$IFDEF DEBUG}
            WriteLn('ERROR: '+DB_Error);
            {$ENDIF}
            Result := False; Exit;
        end;

        Result := True
    end;

    function DatabaseUpdate(Database: LongInt; Query: WideString): Boolean;
    begin
        {$IFDEF DEBUG}
        WriteLn('$ '+Query);
        {$ENDIF}

        if Not DB_IsDatabase(Database) then begin
            {$IFDEF DEBUG}
            WriteLn('ERROR: Wrong database ID provided.');
            {$ENDIF}
            Result := False; Exit;
        end;

        if Not DB_Update(Database, Query) then begin
            {$IFDEF DEBUG}
            WriteLn('ERROR: '+DB_Error);
            {$ENDIF}
            Result := False; Exit;
        end;

        Result := True
    end;

    procedure DatabasePrintValues(Database: Integer);
    var
        Columns, ColumnSize, ColumnID, RowID: LongInt;
        ColumnTypeName, ColumnValue, RowNames, RowValues: String;
    begin
        if Not DB_IsDatabase(Database) then begin
            {$IFDEF DEBUG}
            WriteLn('ERROR: Wrong database ID provided.');
            {$ENDIF}
            Exit;
        end;

        Columns := DB_Columns(Database);
        while (Columns > 0) and DB_NextRow(Database) do begin
            RowValues := '';

            for ColumnID := 0 to Columns - 1 do begin
                ColumnTypeName := '';
                ColumnValue := '';
                ColumnSize := DB_ColumnSize(Database, ColumnID);

                case DB_ColumnType(Database, ColumnID) of
                DB_Type_Long:
                    begin
                        ColumnTypeName := 'Long';

                        if DB_CheckNull(Database, ColumnID) then
                            ColumnValue := 'NULL'
                        else
                            ColumnValue := IntToStr(DB_GetLong(Database, ColumnID));
                    end;

                DB_Type_Float:
                    begin
                        ColumnTypeName := 'Float';

                        if DB_CheckNull(Database, ColumnID) then
                            ColumnValue := 'NULL'
                        else
                            ColumnValue := FormatFloat('#######0.0######', DB_GetFloat(Database, ColumnID));
                    end;

                DB_Type_Double:
                    begin
                        ColumnTypeName := 'Double';

                        if DB_CheckNull(Database, ColumnID) then
                            ColumnValue := 'NULL'
                        else
                            ColumnValue := FormatFloat('##############0.0##############', DB_GetDouble(Database, ColumnID));
                    end;

                DB_Type_Quad:
                    begin
                        ColumnTypeName := 'Quad';

                        if DB_CheckNull(Database, ColumnID) then
                            ColumnValue := 'NULL'
                        else
                            ColumnValue := Int64ToStr(DB_GetQuad(Database, ColumnID));
                    end;

                DB_Type_String:
                    begin
                        ColumnTypeName := 'String';

                        if DB_CheckNull(Database, ColumnID) then
                            ColumnValue := 'NULL'
                        else
                            ColumnValue := DB_GetString(Database, ColumnID);
                    end;

                else
                    begin
                        ColumnTypeName := 'Undefined';

                        if DB_CheckNull(Database, ColumnID) then
                            ColumnValue := 'NULL'
                        else
                            ColumnValue := DB_GetString(Database, ColumnID);
                    end;
                end;

                {$IFDEF VERBOSE}
                WriteLn('['+IntToStr(ColumnID)+'] DB_Type_'+ColumnTypeName+'('+IntToStr(ColumnSize)+'): '+#9+ColumnValue);
                {$ENDIF}

                if RowID = 0 then begin
                    RowNames := RowNames+PadR(DB_ColumnName(Database, ColumnID)+'::'+ColumnTypeName, 17)+'|';
                end;

                RowValues := RowValues+PadR(ColumnValue, 17)+'|';

            end;

            if RowID = 0 then begin
                WriteLn(StringOfChar('-', Length(RowNames)));
                WriteLn(RowNames);
                WriteLn(StringOfChar('-', Length(RowNames)));
            end;

            WriteLn(RowValues);

            Inc(RowID, 1);
        end;
    end;

initialization
    begin
        WriteLn('Database unit has been initialized.');
    end;

finalization
    begin
        DB_Close(DB_All);
        WriteLn('Database unit has been finalized.');
    end;

end.
