require 'csv'
require 'erb'

require 'google/apis/civicinfo_v2'



puts 'Event Manager Initialized!'

def clean_zipcode(zip)
    zip.to_s.rjust(5,'0')[0..4]
end

def clean_phone_number(phone)
    phone = phone.to_s.tr('^0-9', '') 
    if phone.length == 10
        phone = phone
    elsif phone.length == 11 && phone[0] === "1"
        phone =  phone[1..10]
    else
        phone = "Invalid Phone Number"
    end
    phone
end

def legislators_by_zipcode(zip)
    civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
    civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'
    begin
        legislators = civic_info.representative_info_by_address(
            address: zip,
            levels: 'country',
            roles: ['legislatorUpperBody', 'legislatorLowerBody']
        ).officials
    rescue
        "You can find representatives by visiting www.commoncause.org/take-action/find-elected-officials"
    end
    
end 

def save_thank_you_letter(id,form_letter)
    Dir.mkdir('output') unless Dir.exist?('output')

    filename = "output/thanks_#{id}.html"

    File.open(filename, "w") do |file|
        file.puts(form_letter)
    end
end

def count_peak(arr)
    arr.max_by{|a| arr.count(a)}
end

cal = {0=>"sunday",1=>"monday",2=>"tuesday",3=>"wednesday",4=>"thursday",5=>"friday",6=>"saturday"}
contents = CSV.open('event_attendees.csv', headers: true, header_converters: :symbol)
template_letter = File.read('form_letter.erb')
erb_template = ERB.new(template_letter)

hours = []
days = []


contents.each_with_index{|row, i|
    id = row[0]
    name = row[:first_name]

    zipcode = clean_zipcode(row[:zipcode])

    phone_number = clean_phone_number(row[:homephone])

    legislators = legislators_by_zipcode(zipcode)    

    form_letter = erb_template.result(binding)

    reg_date_to_print = DateTime.strptime(row[:regdate],"%m/%d/%y %H:%M")

    hours[i] = reg_date_to_print.hour
    days[i] = reg_date_to_print.wday

    save_thank_you_letter(id,form_letter)
    puts "#{name} #{phone_number}"
}

puts "Most Active Hour is : #{count_peak(hours)}"
puts "Most Active Day is : #{cal[count_peak(days)].capitalize}"


