unit libdb;

interface
    { Database plugins enumeration for the DB_Open() function }
    type TDatabasePluginType = (DB_Plugin_Undefined, DB_Plugin_ODBC, DB_Plugin_SQLite, DB_Plugin_PostgreSQL, DB_Plugin_MySQL);

    { Database column types enumeration for the DB_ColumnType() function }
    type TDatabaseColumnType = (DB_Type_Undefined, DB_Type_Long, DB_Type_String, DB_Type_Float, DB_Type_Double, DB_Type_Quad);

    { Database cursor types enumeration for the DB_QueryX() function }
    type TDatabaseCursorType = (DB_Cursor_Static, DB_Cursor_Dynamic);

    const
        DB_All = -1;
        DB_Any = -1;

    function DB_AffectedRows(DatabaseID: LongInt): LongInt;
    external {$IFDEF WIN32} 'DB_AffectedRows@libdb-0.3.dll cdecl'      {$ELSE} 'DB_AffectedRows@libdb-0.3.so cdecl'      {$ENDIF};

    function DB_CheckNull(DatabaseID: LongInt; Column: Word): Boolean;
    external {$IFDEF WIN32} 'DB_CheckNull@libdb-0.3.dll cdecl'         {$ELSE} 'DB_CheckNull@libdb-0.3.so cdecl'         {$ENDIF};

    procedure DB_Close(DatabaseID: LongInt);
    external {$IFDEF WIN32} 'DB_Close@libdb-0.3.dll cdecl'             {$ELSE} 'DB_Close@libdb-0.3.so cdecl'             {$ENDIF};

    function DB_ColumnIndex(DatabaseID: LongInt; ColumnName: WideString): Word;
    external {$IFDEF WIN32} 'DB_ColumnIndex@libdb-0.3.dll cdecl'       {$ELSE} 'DB_ColumnIndex@libdb-0.3.so cdecl'       {$ENDIF};

    function DB_ColumnName(DatabaseID: LongInt; Column: Word): PChar;
    external {$IFDEF WIN32} 'DB_ColumnName@libdb-0.3.dll cdecl'        {$ELSE} 'DB_ColumnName@libdb-0.3.so cdecl'        {$ENDIF};

    function DB_Columns(DatabaseID: LongInt): Word;
    external {$IFDEF WIN32} 'DB_Columns@libdb-0.3.dll cdecl'           {$ELSE} 'DB_Columns@libdb-0.3.so cdecl'           {$ENDIF};

    function DB_ColumnSize(DatabaseID: LongInt; Column: Word): LongInt;
    external {$IFDEF WIN32} 'DB_ColumnSize@libdb-0.3.dll cdecl'        {$ELSE} 'DB_ColumnSize@libdb-0.3.so cdecl'        {$ENDIF};

    function DB_ColumnType(DatabaseID: LongInt; Column: Word): TDatabaseColumnType;
    external {$IFDEF WIN32} 'DB_ColumnType@libdb-0.3.dll cdecl'        {$ELSE} 'DB_ColumnType@libdb-0.3.so cdecl'        {$ENDIF};

    function DB_DriverDescription(): PChar;
    external {$IFDEF WIN32} 'DB_DriverDescription@libdb-0.3.dll cdecl' {$ELSE} 'DB_DriverDescription@libdb-0.3.so cdecl' {$ENDIF};

    function DB_DriverName(): PChar;
    external {$IFDEF WIN32} 'DB_DriverName@libdb-0.3.dll cdecl'        {$ELSE} 'DB_DriverName@libdb-0.3.so cdecl'        {$ENDIF};

    function DB_Error(): PChar;
    external {$IFDEF WIN32} 'DB_Error@libdb-0.3.dll cdecl'             {$ELSE} 'DB_Error@libdb-0.3.so cdecl'             {$ENDIF};

    function DB_ExamineDrivers(): Boolean;
    external {$IFDEF WIN32} 'DB_ExamineDrivers@libdb-0.3.dll cdecl'    {$ELSE} 'DB_ExamineDrivers@libdb-0.3.so cdecl'    {$ENDIF};

    procedure DB_FinishQuery(DatabaseID: LongInt);
    external {$IFDEF WIN32} 'DB_FinishQuery@libdb-0.3.dll cdecl'       {$ELSE} 'DB_FinishQuery@libdb-0.3.so cdecl'       {$ENDIF};

    function DB_FirstRow(DatabaseID: LongInt): Boolean;
    external {$IFDEF WIN32} 'DB_FirstRow@libdb-0.3.dll cdecl'          {$ELSE} 'DB_FirstRow@libdb-0.3.so cdecl'          {$ENDIF};

    function DB_GetDouble(DatabaseID: LongInt; Column: Word): Double;
    external {$IFDEF WIN32} 'DB_GetDouble@libdb-0.3.dll cdecl'         {$ELSE} 'DB_GetDouble@libdb-0.3.so cdecl'         {$ENDIF};

    function DB_GetFloat(DatabaseID: LongInt; Column: Word): Single;
    external {$IFDEF WIN32} 'DB_GetFloat@libdb-0.3.dll cdecl'          {$ELSE} 'DB_GetFloat@libdb-0.3.so cdecl'          {$ENDIF};

    function DB_GetLong(DatabaseID: LongInt; Column: Word): LongInt;
    external {$IFDEF WIN32} 'DB_GetLong@libdb-0.3.dll cdecl'           {$ELSE} 'DB_GetLong@libdb-0.3.so cdecl'           {$ENDIF};

    //function DB_GetQuad(DatabaseID: LongInt; Column: Word): Int64; // return type of Int64 doesn't work properly because of the bug in ScriptCore?..
    function DB_GetQuad(DatabaseID: LongInt; Column: Word): LongInt;
    external {$IFDEF WIN32} 'DB_GetQuad@libdb-0.3.dll cdecl'           {$ELSE} 'DB_GetQuad@libdb-0.3.so cdecl'           {$ENDIF};

    function DB_GetString(DatabaseID: LongInt; Column: Word): PChar;
    external {$IFDEF WIN32} 'DB_GetString@libdb-0.3.dll cdecl'         {$ELSE} 'DB_GetString@libdb-0.3.so cdecl'         {$ENDIF};

    function DB_IsDatabase(DatabaseID: LongInt): Boolean;
    external {$IFDEF WIN32} 'DB_IsDatabase@libdb-0.3.dll cdecl'        {$ELSE} 'DB_IsDatabase@libdb-0.3.so cdecl'        {$ENDIF};

    function DB_NextDriver(): Boolean;
    external {$IFDEF WIN32} 'DB_NextDriver@libdb-0.3.dll cdecl'        {$ELSE} 'DB_NextDriver@libdb-0.3.so cdecl'        {$ENDIF};

    function DB_NextRow(DatabaseID: LongInt): Boolean;
    external {$IFDEF WIN32} 'DB_NextRow@libdb-0.3.dll cdecl'           {$ELSE} 'DB_NextRow@libdb-0.3.so cdecl'           {$ENDIF};

    function DB_Open(DatabaseID: LongInt; DatabaseName, User, Password: WideString; Plugin: TDatabasePluginType): LongInt;
    external {$IFDEF WIN32} 'DB_Open@libdb-0.3.dll cdecl'              {$ELSE} 'DB_Open@libdb-0.3.so cdecl'              {$ENDIF};

    function DB_PreviousRow(DatabaseID: LongInt): Boolean;
    external {$IFDEF WIN32} 'DB_PreviousRow@libdb-0.3.dll cdecl'       {$ELSE} 'DB_PreviousRow@libdb-0.3.so cdecl'       {$ENDIF};

    function DB_Query(DatabaseID: LongInt; Query: WideString): Boolean;
    external {$IFDEF WIN32} 'DB_Query@libdb-0.3.dll cdecl'             {$ELSE} 'DB_Query@libdb-0.3.so cdecl'             {$ENDIF};

    function DB_QueryX(DatabaseID: LongInt; Query: WideString; Cursor: TDatabaseCursorType): Boolean;
    external {$IFDEF WIN32} 'DB_QueryX@libdb-0.3.dll cdecl'            {$ELSE} 'DB_QueryX@libdb-0.3.so cdecl'            {$ENDIF};

    procedure DB_SetDouble(DatabaseID: LongInt; StatementIndex: Word; Value: Double);
    external {$IFDEF WIN32} 'DB_SetDouble@libdb-0.3.dll cdecl'         {$ELSE} 'DB_SetDouble@libdb-0.3.so cdecl'         {$ENDIF};

    procedure DB_SetFloat(DatabaseID: LongInt; StatementIndex: Word; Value: Single);
    external {$IFDEF WIN32} 'DB_SetFloat@libdb-0.3.dll cdecl'          {$ELSE} 'DB_SetFloat@libdb-0.3.so cdecl'          {$ENDIF};

    procedure DB_SetLong(DatabaseID: LongInt; StatementIndex: Word; Value: LongInt);
    external {$IFDEF WIN32} 'DB_SetLong@libdb-0.3.dll cdecl'           {$ELSE} 'DB_SetLong@libdb-0.3.so cdecl'           {$ENDIF};

    procedure DB_SetNull(DatabaseID: LongInt; StatementIndex: Word);
    external {$IFDEF WIN32} 'DB_SetNull@libdb-0.3.dll cdecl'           {$ELSE} 'DB_SetNull@libdb-0.3.so cdecl'           {$ENDIF};

    procedure DB_SetQuad(DatabaseID: LongInt; StatementIndex: Word; Value: Int64);
    external {$IFDEF WIN32} 'DB_SetQuad@libdb-0.3.dll cdecl'           {$ELSE} 'DB_SetQuad@libdb-0.3.so cdecl'           {$ENDIF};

    procedure DB_SetString(DatabaseID: LongInt; StatementIndex: Word; Value: WideString);
    external {$IFDEF WIN32} 'DB_SetString@libdb-0.3.dll cdecl'         {$ELSE} 'DB_SetString@libdb-0.3.so cdecl'         {$ENDIF};

    function DB_Update(DatabaseID: LongInt; Query: WideString): Boolean;
    external {$IFDEF WIN32} 'DB_Update@libdb-0.3.dll cdecl'            {$ELSE} 'DB_Update@libdb-0.3.so cdecl'            {$ENDIF};

    procedure DB_UseMySQL(LibraryPath: WideString);
    external {$IFDEF WIN32} 'DB_UseMySQL@libdb-0.3.dll cdecl'          {$ELSE} 'DB_UseMySQL@libdb-0.3.so cdecl'          {$ENDIF};

    function DB_UseODBC(): Boolean;
    external {$IFDEF WIN32} 'DB_UseODBC@libdb-0.3.dll cdecl'           {$ELSE} 'DB_UseODBC@libdb-0.3.so cdecl'           {$ENDIF};

    procedure DB_UsePostgreSQL();
    external {$IFDEF WIN32} 'DB_UsePostgreSQL@libdb-0.3.dll cdecl'     {$ELSE} 'DB_UsePostgreSQL@libdb-0.3.so cdecl'     {$ENDIF};

    procedure DB_UseSQLite();
    external {$IFDEF WIN32} 'DB_UseSQLite@libdb-0.3.dll cdecl'         {$ELSE} 'DB_UseSQLite@libdb-0.3.so cdecl'         {$ENDIF};

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function DB_GetVersion(): Word;
    external {$IFDEF WIN32} 'DB_GetVersion@libdb-0.3.dll cdecl'        {$ELSE} 'DB_GetVersion@libdb-0.3.so cdecl'        {$ENDIF};

initialization
    begin
        WriteLn('LibDB unit has been initialized.');
        WriteLn('Using "libdb v'+FormatFloat('#0.0', 0.1 * DB_GetVersion)+'" library.');
    end;

finalization
    begin
        WriteLn('LibDB unit has been finalized.');
    end;

end.
