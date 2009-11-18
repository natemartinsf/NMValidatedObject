@import "../lib/Employee.j"
@import "../lib/Department.j"
@import "../lib/Project.j"


[Test for: Employee
	beforeEach: function() {
		this.employee = [[Employee alloc] init];
		this.exampleProject = [[Project alloc] init];
		this.exampleDepartment = [[Department alloc] init];		
		[this.employee insertObject:this.exampleProject inProjectsAtIndex:0];
	   }
	checking: function() {
		[Employee should: "be able to initialize"
		   by: function() {
			 [@"Employee" shouldEqual:[this.employee className]];
		   }]
		[Employee should: "set inverse relationships for department"
			by: function() {
				var department = [[Department alloc] init];
				[this.employee setDepartment:department];
				[[[department employees] containsObject:this.employee] shouldEqual:YES]; 
			}]
		[Employee should: "set inverse relationships for department when removing"
			by: function() {
				
				[this.employee setDepartment:this.exampleDepartment];
				[[[this.exampleDepartment employees] containsObject:this.employee] shouldEqual:YES];
				[this.employee setDepartment:nil];
				[[[this.exampleDepartment employees] containsObject:this.employee] shouldEqual:NO];				
				
			}]
		[Employee should: "set inverse relationships for department when replacing"
			by: function() {
				[this.employee setDepartment:this.exampleDepartment];
				var department = [[Department alloc] init];
				[this.employee setDepartment:department];
				[[[department employees] containsObject:this.employee] shouldEqual:YES]; 
				[[[this.exampleDepartment employees] containsObject:this.Employee] shouldEqual:NO];
			}]
		[Employee should: "set inverse relationships for projects"
			by: function() {
				var project = [[Project alloc] init];
				[this.employee insertObject:project inProjectsAtIndex:0];
				[[[project employees] containsObject:this.employee] shouldEqual:YES];
			}]
		[Employee should: "update inverse relationships for projects when removing objects"
			by: function() {
				var index = [[this.employee projects] indexOfObject:this.exampleProject];
				[this.employee removeObjectFromProjectsAtIndex:index];
				[[[this.exampleProject employees] containsObject:this.employee] shouldEqual:NO];
			}]
		[Employee should: "update inverse relationships for projects when replacing objects"
			by: function() {
				var project = [[Project alloc] init],
					index = [[this.employee projects] indexOfObject:this.exampleProject];

				[this.employee removeObjectFromProjectsAtIndex:index];
				[this.employee insertObject:project inProjectsAtIndex:index];
				[[[this.exampleProject employees] containsObject:this.employee] shouldEqual:NO];
				[[[project employees] containsObject:this.employee] shouldEqual:YES];
			}]
		[Employee should: "validate length of name key"
			by: function() {
				[this.employee setName:@"validname"];
				[this.employee setName:@"a"];
				[[this.employee name] shouldEqual:@"validname"];
				[this.employee setName:@"averyveryveryveryveryveryveryveryverylongname"];
				[[this.employee name] shouldEqual:@"validname"];
			}]
		[Employee should: "validate exclusion of job title key"
			by: function() {
				[this.employee setJobTitle:@"Valid Job Title"];
				[this.employee setJobTitle:@"Paper Pusher"];
				[[this.employee jobTitle] shouldEqual:@"Valid Job Title"];
			}]

		[Employee should: "validate format of email"
			by: function() {
				[this.employee setEmail:@"valid@email.com"];
				[this.employee setEmail:@"fake.email.com"];
				[[this.employee email] shouldEqual:@"valid@email.com"];
			}]
			
		[Employee should: "validate numericality of salary"
			by: function() {
				[this.employee setSalary:60000];
				[this.employee setSalary:@"not a number!"];
				[[this.employee salary] shouldEqual:60000];
			}]
			
		[Employee should: "validate presence of computer type"
			by: function() {
				[this.employee setComputerType:@"mac"];
				[this.employee setComputerType:nil];
				[[this.employee computerType] shouldEqual:@"mac"];
			}]
			
   }]
   
[Test for: Department
	beforeEach: function() {
         this.department = [[Department alloc] init];
         this.department2 = [[Department alloc] init];
		     this.exampleEmployee = [[Employee alloc] init];
       }
	checking: function() {
		[Department should: "be able to initialize"
			by: function() {
			
				
				[[this.department className] shouldEqual:@"Department"];
			}]
		[Department should: "be able to add employees"
			by: function() {
				var	employee1 = [[Employee alloc] init],
					employee2 = [[Employee alloc] init];
				
				[this.department insertObject:employee1 inEmployeesAtIndex:0];
				[this.department insertObject:employee2 inEmployeesAtIndex:1];
				[[[this.department employees] containsObject:employee1] shouldEqual:YES];
				[[[this.department employees] containsObject:employee2] shouldEqual:YES];
			}]
		
		[Department should: "set inverse relationships for employees"
			by: function() {
			  var testDepartment = [[Department alloc] init];
				var employee1 = [[Employee alloc] init];
				var employee2 = [[Employee alloc] init];
				var employee3 = [[Employee alloc] init];
				[testDepartment insertObject:employee1 inEmployeesAtIndex:0];
				[testDepartment insertObject:employee2 inEmployeesAtIndex:1];
				[testDepartment insertObject:employee3 inEmployeesAtIndex:2];


				[testDepartment shouldEqual:[employee1 department]];
				[testDepartment shouldEqual:[employee2 department]];
				[testDepartment shouldEqual:[employee3 department]];

			}]
			
		[Department should: "set inverse relationships for employees when removing"
			by: function() {
				[this.department insertObject:this.exampleEmployee inEmployeesAtIndex:0];
				[this.department shouldEqual:[this.exampleEmployee department]];
				[this.department removeObjectFromEmployeesAtIndex:0];
				[[this.exampleEmployee className] shouldEqual:@"Employee"];
				[[this.exampleEmployee department]  shouldEqual:nil];
			}]
		[Department should: "set inverse relationships for employees when replacing"
			by: function() {
				[this.department insertObject:this.exampleEmployee inEmployeesAtIndex:0];
				[this.department shouldEqual:[this.exampleEmployee department]];
				var employee1 = [[Employee alloc] init];
				[this.department removeObjectFromEmployeesAtIndex:0];
				[this.department insertObject:employee1 inEmployeesAtIndex:0];
				[[this.exampleEmployee className] shouldEqual:@"Employee"];
				[[this.exampleEmployee department]  shouldEqual:nil];
				[this.department shouldEqual:[employee1 department]];
			}]
		[Department should: "run custom validations"
			by: function() {
				[[[this.department employees] count] shouldEqual:1]; //already had one automatically
				[this.department removeObjectFromEmployeesAtIndex:0];
				[[[this.department employees] count] shouldEqual:1]; //shouldn't be allowed to go down to zero
			}]
			
		[Department should: "validate inclusion of purpose key"
			by: function() {
				[this.department setPurpose:@"Research"];
				[this.department setPurpose:@"goofing off"];
				[@"Research" shouldEqual:[this.department purpose]];
			}]

	}]
	
[Test for: Project
	beforeEach: function() {
		this.project = [[Project alloc] init];
		this.exampleEmployee = [[Employee alloc] init];
		[this.project insertObject:this.exampleEmployee inEmployeesAtIndex:0];

		}
	checking: function() {
		[Project should: "be able to initialize"
			by: function() {
				[[this.project className] shouldEqual:@"Project"]
			}]
		[Project should: "set inverse relationships for employees when adding objects"
			by: function() {
				var employee = [[Employee alloc] init];
				[this.project insertObject:employee inEmployeesAtIndex:0];
				[[[employee projects] containsObject:this.project] shouldEqual:YES];
			}]
		[Project should: "update inverse relationships for employees when removing objects"
			by: function() {
				var index = [[this.project employees] indexOfObject:this.exampleEmployee];
				[this.project removeObjectFromEmployeesAtIndex:index];
				[[[this.exampleEmployee projects] containsObject:this.project] shouldEqual:NO];
			}]
		[Project should: "update inverse relationships for employees when replacing objects"
			by: function() {
				var employee = [[Employee alloc] init],
					index = [[this.project employees] indexOfObject:this.exampleEmployee];

				[this.project removeObjectFromEmployeesAtIndex:index];
				[this.project insertObject:employee inEmployeesAtIndex:index];
				[[[this.exampleEmployee projects] containsObject:this.project] shouldEqual:NO];
				[[[employee projects] containsObject:this.project] shouldEqual:YES];
			}]
	}]

