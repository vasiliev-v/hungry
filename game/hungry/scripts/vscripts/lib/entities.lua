Events:CallAfter( 'Activate', function()
    function Entities:FindByClassAndNamePatterns( sClassPattern, sNamePattern )
        local qResult = {}
        local hEnt = self:First()

        while hEnt do
            if hEnt:GetClassname():match( sClassPattern ) and hEnt:GetName():match( sNamePattern ) then
                table.insert( qResult, hEnt )
            end

            hEnt = self:Next( hEnt )
        end

        return qResult
    end
end )