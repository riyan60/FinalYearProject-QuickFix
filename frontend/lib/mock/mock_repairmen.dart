List<Map<String, dynamic>> mockRepairmen = [
{
"id":"goa1",
"account_id":"goa1",
"name":"Rohit Electrician",
"phone":"+91 9821000001",
"address":"Panjim, Goa",
"city":"Panjim",
"latitude":15.4909,
"longitude":73.8278,
"experience":5,
"skills":["Electrician"],
"specialization":"Electrician",
"hourly_rate":400,
"availability_status":"available",
"emergency_service_enabled":true,
"rating":4.4,
"bio":"Expert in home wiring and electrical repairs.",
"profile_pic":"",
"is_verified":true,
"created_at":"2026-01-10T10:00:00.000Z"
},

{
"id":"goa2",
"account_id":"goa2",
"name":"Santosh Plumber",
"phone":"+91 9821000002",
"address":"Margao, Goa",
"city":"Margao",
"latitude":15.2993,
"longitude":73.9550,
"experience":7,
"skills":["Plumber"],
"specialization":"Plumber",
"hourly_rate":350,
"availability_status":"available",
"emergency_service_enabled":true,
"rating":4.6,
"bio":"Specialist in pipe fitting and bathroom repairs.",
"profile_pic":"",
"is_verified":true,
"created_at":"2026-01-12T10:00:00.000Z"
},

{
"id":"goa3",
"name":"Ajay Mechanic",
"account_id":"goa3",
"phone":"+91 9821000003",
"address":"Ponda, Goa",
"city":"Ponda",
"latitude":15.4020,
"longitude":74.0150,
"experience":8,
"skills":["Mechanic"],
"specialization":"Mechanic",
"hourly_rate":500,
"availability_status":"available",
"emergency_service_enabled":false,
"rating":4.2,
"bio":"Bike and scooter repair expert.",
"profile_pic":"",
"is_verified":true,
"created_at":"2026-01-11T10:00:00.000Z"
},

{
"id":"goa4",
"name":"Mahesh Carpenter",
"account_id":"goa4",
"phone":"+91 9821000004",
"address":"Quepem, Goa",
"city":"Quepem",
"latitude":15.2125,
"longitude":74.0770,
"experience":10,
"skills":["Carpenter"],
"specialization":"Carpenter",
"hourly_rate":420,
"availability_status":"available",
"emergency_service_enabled":false,
"rating":4.7,
"bio":"Furniture repair and custom woodwork.",
"profile_pic":"",
"is_verified":true,
"created_at":"2026-01-13T10:00:00.000Z"
},

{
"id":"goa5",
"name":"Suresh AC Technician",
"account_id":"goa5",
"phone":"+91 9821000005",
"address":"Curchorem, Goa",
"city":"Curchorem",
"latitude":15.2620,
"longitude":74.1080,
"experience":6,
"skills":["AC repair"],
"specialization":"AC repair",
"hourly_rate":480,
"availability_status":"available",
"emergency_service_enabled":true,
"rating":4.3,
"bio":"AC installation and servicing expert.",
"profile_pic":"",
"is_verified":true,
"created_at":"2026-01-14T10:00:00.000Z"
},

{
"id":"goa6",
"name":"Rakesh Cleaner",
"account_id":"goa6",
"phone":"+91 9821000006",
"address":"Cancona, Goa",
"city":"Cancona",
"latitude":15.0153,
"longitude":74.0537,
"experience":4,
"skills":["Cleaning"],
"specialization":"Cleaning",
"hourly_rate":250,
"availability_status":"available",
"emergency_service_enabled":false,
"rating":4.1,
"bio":"Professional home and office cleaning.",
"profile_pic":"",
"is_verified":true,
"created_at":"2026-01-15T10:00:00.000Z"
},

// remaining sample repairmen

{
"id":"goa7","account_id":"goa7","name":"Vijay Electrician","phone":"+91 9821000007","address":"Panjim, Goa","city":"Panjim","latitude":15.49,"longitude":73.83,"experience":9,"skills":["Electrician"],"specialization":"Electrician","hourly_rate":450,"availability_status":"available","emergency_service_enabled":true,"rating":4.6,"bio":"Electrical troubleshooting specialist.","profile_pic":"","is_verified":true,"created_at":"2026-01-16T10:00:00.000Z"
},

{
"id":"goa8","account_id":"goa8","name":"Kiran Plumber","phone":"+91 9821000008","address":"Margao, Goa","city":"Margao","latitude":15.30,"longitude":73.96,"experience":5,"skills":["Plumber"],"specialization":"Plumber","hourly_rate":360,"availability_status":"available","emergency_service_enabled":true,"rating":4.2,"bio":"Kitchen and bathroom plumbing.","profile_pic":"","is_verified":true,"created_at":"2026-01-16T10:00:00.000Z"
},

{
"id":"goa9","account_id":"goa9","name":"Deepak Mechanic","phone":"+91 9821000009","address":"Ponda, Goa","city":"Ponda","latitude":15.40,"longitude":74.02,"experience":7,"skills":["Mechanic"],"specialization":"Mechanic","hourly_rate":470,"availability_status":"available","emergency_service_enabled":false,"rating":4.3,"bio":"Two-wheeler service specialist.","profile_pic":"","is_verified":true,"created_at":"2026-01-16T10:00:00.000Z"
},

{
"id":"goa10","account_id":"goa10","name":"Sunil Carpenter","phone":"+91 9821000010","address":"Quepem, Goa","city":"Quepem","latitude":15.21,"longitude":74.08,"experience":12,"skills":["Carpenter"],"specialization":"Carpenter","hourly_rate":430,"availability_status":"available","emergency_service_enabled":false,"rating":4.7,"bio":"Wood furniture repair expert.","profile_pic":"","is_verified":true,"created_at":"2026-01-16T10:00:00.000Z"
},

{
"id":"goa11","account_id":"goa11","name":"Arun AC Repair","phone":"+91 9821000011","address":"Curchorem, Goa","city":"Curchorem","latitude":15.26,"longitude":74.10,"experience":6,"skills":["AC repair"],"specialization":"AC repair","hourly_rate":500,"availability_status":"available","emergency_service_enabled":true,"rating":4.4,"bio":"Split and window AC servicing.","profile_pic":"","is_verified":true,"created_at":"2026-01-16T10:00:00.000Z"
},

{
"id":"goa12","account_id":"goa12","name":"Ravi Cleaner","phone":"+91 9821000012","address":"Cancona, Goa","city":"Cancona","latitude":15.01,"longitude":74.05,"experience":3,"skills":["Cleaning"],"specialization":"Cleaning","hourly_rate":240,"availability_status":"available","emergency_service_enabled":false,"rating":4.0,"bio":"Deep cleaning services.","profile_pic":"","is_verified":true,"created_at":"2026-01-16T10:00:00.000Z"
},

{
"id":"goa13","account_id":"goa13","name":"Nikhil Electrician","phone":"+91 9821000013","address":"Panjim, Goa","city":"Panjim","latitude":15.49,"longitude":73.82,"experience":8,"skills":["Electrician"],"specialization":"Electrician","hourly_rate":420,"availability_status":"available","emergency_service_enabled":true,"rating":4.5,"bio":"House wiring expert.","profile_pic":"","is_verified":true,"created_at":"2026-01-16T10:00:00.000Z"
},

{
"id":"goa14","account_id":"goa14","name":"Sameer Plumber","phone":"+91 9821000014","address":"Margao, Goa","city":"Margao","latitude":15.29,"longitude":73.95,"experience":6,"skills":["Plumber"],"specialization":"Plumber","hourly_rate":340,"availability_status":"available","emergency_service_enabled":true,"rating":4.2,"bio":"Leak repair specialist.","profile_pic":"","is_verified":true,"created_at":"2026-01-16T10:00:00.000Z"
},

{
"id":"goa15","account_id":"goa15","name":"Prakash Mechanic","phone":"+91 9821000015","address":"Ponda, Goa","city":"Ponda","latitude":15.40,"longitude":74.01,"experience":9,"skills":["Mechanic"],"specialization":"Mechanic","hourly_rate":480,"availability_status":"available","emergency_service_enabled":false,"rating":4.4,"bio":"Engine repair specialist.","profile_pic":"","is_verified":true,"created_at":"2026-01-16T10:00:00.000Z"
},

// continue pattern for remaining entries

{
"id":"goa16","account_id":"goa16","name":"Raj Carpenter","phone":"+91 9821000016","address":"Quepem, Goa","city":"Quepem","latitude":15.21,"longitude":74.07,"experience":7,"skills":["Carpenter"],"specialization":"Carpenter","hourly_rate":410,"availability_status":"available","emergency_service_enabled":false,"rating":4.3,"bio":"Wood polishing and repairs.","profile_pic":"","is_verified":true,"created_at":"2026-01-16T10:00:00.000Z"
},

{
"id":"goa17","account_id":"goa17","name":"Manoj AC Technician","phone":"+91 9821000017","address":"Curchorem, Goa","city":"Curchorem","latitude":15.26,"longitude":74.11,"experience":5,"skills":["AC repair"],"specialization":"AC repair","hourly_rate":470,"availability_status":"available","emergency_service_enabled":true,"rating":4.1,"bio":"AC gas refill specialist.","profile_pic":"","is_verified":true,"created_at":"2026-01-16T10:00:00.000Z"
},

{
"id":"goa18","account_id":"goa18","name":"Kunal Cleaner","phone":"+91 9821000018","address":"Cancona, Goa","city":"Cancona","latitude":15.02,"longitude":74.05,"experience":4,"skills":["Cleaning"],"specialization":"Cleaning","hourly_rate":260,"availability_status":"available","emergency_service_enabled":false,"rating":4.0,"bio":"Apartment cleaning expert.","profile_pic":"","is_verified":true,"created_at":"2026-01-16T10:00:00.000Z"
},

// simplified entries to reach 30

{"id":"goa19","account_id":"goa19","name":"Amit Electrician","phone":"+91 9821000019","address":"Panjim","city":"Panjim","latitude":15.49,"longitude":73.83,"experience":6,"skills":["Electrician"],"specialization":"Electrician","hourly_rate":430,"availability_status":"available","emergency_service_enabled":true,"rating":4.3,"bio":"Electrical maintenance.","profile_pic":"","is_verified":true,"created_at":"2026-01-16T10:00:00.000Z"},
{"id":"goa20","account_id":"goa20","name":"Ganesh Plumber","phone":"+91 9821000020","address":"Margao","city":"Margao","latitude":15.29,"longitude":73.96,"experience":8,"skills":["Plumber"],"specialization":"Plumber","hourly_rate":360,"availability_status":"available","emergency_service_enabled":true,"rating":4.5,"bio":"Pipe installation.","profile_pic":"","is_verified":true,"created_at":"2026-01-16T10:00:00.000Z"},
{"id":"goa21","account_id":"goa21","name":"Rahul Mechanic","phone":"+91 9821000021","address":"Ponda","city":"Ponda","latitude":15.40,"longitude":74.02,"experience":7,"skills":["Mechanic"],"specialization":"Mechanic","hourly_rate":480,"availability_status":"available","emergency_service_enabled":false,"rating":4.2,"bio":"Bike servicing.","profile_pic":"","is_verified":true,"created_at":"2026-01-16T10:00:00.000Z"},
{"id":"goa22","account_id":"goa22","name":"Dev Carpenter","phone":"+91 9821000022","address":"Quepem","city":"Quepem","latitude":15.21,"longitude":74.07,"experience":9,"skills":["Carpenter"],"specialization":"Carpenter","hourly_rate":420,"availability_status":"available","emergency_service_enabled":false,"rating":4.4,"bio":"Furniture fixing.","profile_pic":"","is_verified":true,"created_at":"2026-01-16T10:00:00.000Z"},
{"id":"goa23","account_id":"goa23","name":"Arvind AC Repair","phone":"+91 9821000023","address":"Curchorem","city":"Curchorem","latitude":15.26,"longitude":74.10,"experience":6,"skills":["AC repair"],"specialization":"AC repair","hourly_rate":500,"availability_status":"available","emergency_service_enabled":true,"rating":4.3,"bio":"AC maintenance.","profile_pic":"","is_verified":true,"created_at":"2026-01-16T10:00:00.000Z"},
{"id":"goa24","account_id":"goa24","name":"Imran Cleaner","phone":"+91 9821000024","address":"Cancona","city":"Cancona","latitude":15.01,"longitude":74.05,"experience":5,"skills":["Cleaning"],"specialization":"Cleaning","hourly_rate":250,"availability_status":"available","emergency_service_enabled":false,"rating":4.1,"bio":"Deep cleaning.","profile_pic":"","is_verified":true,"created_at":"2026-01-16T10:00:00.000Z"},
{"id":"goa25","account_id":"goa25","name":"Tejas Electrician","phone":"+91 9821000025","address":"Panjim","city":"Panjim","latitude":15.49,"longitude":73.82,"experience":8,"skills":["Electrician"],"specialization":"Electrician","hourly_rate":450,"availability_status":"available","emergency_service_enabled":true,"rating":4.5,"bio":"Electrical services.","profile_pic":"","is_verified":true,"created_at":"2026-01-16T10:00:00.000Z"},
{"id":"goa26","account_id":"goa26","name":"Pravin Plumber","phone":"+91 9821000026","address":"Margao","city":"Margao","latitude":15.30,"longitude":73.95,"experience":7,"skills":["Plumber"],"specialization":"Plumber","hourly_rate":350,"availability_status":"available","emergency_service_enabled":true,"rating":4.4,"bio":"Bathroom repairs.","profile_pic":"","is_verified":true,"created_at":"2026-01-16T10:00:00.000Z"},
{"id":"goa27","account_id":"goa27","name":"Sanjay Mechanic","phone":"+91 9821000027","address":"Ponda","city":"Ponda","latitude":15.40,"longitude":74.01,"experience":10,"skills":["Mechanic"],"specialization":"Mechanic","hourly_rate":520,"availability_status":"available","emergency_service_enabled":false,"rating":4.6,"bio":"Engine specialist.","profile_pic":"","is_verified":true,"created_at":"2026-01-16T10:00:00.000Z"},
{"id":"goa28","account_id":"goa28","name":"Kishore Carpenter","phone":"+91 9821000028","address":"Quepem","city":"Quepem","latitude":15.21,"longitude":74.08,"experience":9,"skills":["Carpenter"],"specialization":"Carpenter","hourly_rate":430,"availability_status":"available","emergency_service_enabled":false,"rating":4.3,"bio":"Wood furniture work.","profile_pic":"","is_verified":true,"created_at":"2026-01-16T10:00:00.000Z"},
{"id":"goa29","account_id":"goa29","name":"Akash AC Technician","phone":"+91 9821000029","address":"Curchorem","city":"Curchorem","latitude":15.26,"longitude":74.10,"experience":6,"skills":["AC repair"],"specialization":"AC repair","hourly_rate":480,"availability_status":"available","emergency_service_enabled":true,"rating":4.4,"bio":"AC repair services.","profile_pic":"","is_verified":true,"created_at":"2026-01-16T10:00:00.000Z"},
{"id":"goa30","account_id":"goa30","name":"Faizan Cleaner","phone":"+91 9821000030","address":"Cancona","city":"Cancona","latitude":15.01,"longitude":74.05,"experience":4,"skills":["Cleaning"],"specialization":"Cleaning","hourly_rate":240,"availability_status":"available","emergency_service_enabled":false,"rating":4.0,"bio":"Professional cleaning.","profile_pic":"","is_verified":true,"created_at":"2026-01-16T10:00:00.000Z"}

];