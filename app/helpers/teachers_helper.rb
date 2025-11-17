module TeachersHelper
    def format_gender(code)
        case code
        when 'L' then 'Laki-Laki'
        when 'P' then 'Perempuan'
        else '-'
        end
    end
end
