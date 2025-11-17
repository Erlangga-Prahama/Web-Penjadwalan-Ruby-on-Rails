module ApplicationHelper
    def sorted_class_rooms
        ClassRoom.all.sort_by do |t|
            roman_part = t.name.split('.').first
            priority = { "VII" => 1, "VIII" => 2, "IX" => 3 }[roman_part] || 0
            [priority, t.name]
        end
    end

    def day_order
        ['Senin', 'Selasa', 'Rabu', 'Kamis', "Jumat"]
    end
end
