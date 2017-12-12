## import all necessary packages and functions
import csv # read and write csv files
from datetime import datetime # operations to parse dates
from pprint import pprint # use to print data structures

def print_first_point(filename):
    '''
    This function prints and returns the first data point (seconde row) from
    a csv file that includes a header row.
    '''

    # print city name for reference
    city = filename.split('-')[0].split('/')[-1]
    print('\nCity: {}'.format(city))

    with open(filename, 'r') as f_in:
        # Use the csv library to set up a DictReader object.
        trip_reader = csv.DictReader(f_in)
        # Use a function on the DictReader object to read the first trip from data file
        # and store it in a variable.
        first_trip = next(trip_reader)
        # Use the pprint library to print th first trip
        pprint(first_trip)

    # Output city name and first trip for later testing
    return(city, first_trip)

data_files = ['./Documents/Udacity/Project2/Chicago-Divvy-2016.csv',
              './Documents/Udacity/Project2/NYC-CitiBike-2016.csv',
              './Documents/Udacity/Project2/Washington-CapitalBikeshare-2016.csv']

# print the first trip from each file, store in dictionary
example_trips = {}
for data_file in data_files:
    city, first_trip = print_first_point(data_file)
    example_trips[city] = first_trip

print(example_trips)

def duration_in_mins(datum, city):
    """
    Takes as input a dictionary containing info about a single trip (datum) and
    its origin city (city) and returns the trip duration in units of minutes.

    Remember that Washington is in terms of milliseconds while Chicago and NYC
    are in terms of seconds.

    HINT: The csv module reads in all of the data as strings, including numeric
    values. You will need a function to convert the strings into an appropriate
    numeric type when making your transformations.
    see https://docs.python.org/3/library/functions.html
    """

    # YOUR CODE HERE
    if city == 'Washington':
        duration = float(datum['Duration (ms)']) / 1000 / 60

    else:
        duration = float(datum['tripduration']) / 60

    return duration

tests = {'NYC': 13.9833,
         'Chicago': 15.4333,
         'Washington': 7.1231}

for city in tests:
    assert abs(duration_in_mins(example_trips[city], city) - tests[city]) < .001
    print('{} match successful'.format(city))

def time_of_trip(datum, city):
    """
    Takes as input a dictionary containing info about a single trip (datum) and
    its origin city (city) and returns the month, hour, and day of the week in
    which the trip was made.

    Remember that NYC includes seconds, while Washington and Chicago do not.

    HINT: You should use the datetime module to parse the original date
    strings into a format that is useful for extracting the desired information.
    see https://docs.python.org/3/library/datetime.html#strftime-and-strptime-behavior
    """
    timedic = {}
    if city == 'NYC':
        print(datum['starttime'])
        dt = datetime.strptime(datum['starttime'], '%m/%d/%Y %H:%M:%S')
        (month, hour, day_of_week) = (dt.month, dt.hour, dt.strftime('%A'))
        timedic[city] = (month, hour, day_of_week)

    elif city == 'Chicago':
        print(datum['starttime'])
        dt = datetime.strptime(datum['starttime'], '%m/%d/%y %H:%M')
        (month, hour, day_of_week) = (dt.month, dt.hour, dt.strftime('%A'))
        timedic[city] = (month, hour, day_of_week)

    else:
        print(datum['Start date'])
        dt = datetime.strptime(datum['Start date'], '%m/%d/%y %H:%M')
        (month, hour, day_of_week) = (dt.month, dt.hour, dt.strftime('%A'))
        timedic[city] = (month, hour, day_of_week)
    return (month, hour, day_of_week)

tests = {'NYC': (1, 0, 'Friday'),
         'Chicago': (3, 23, 'Thursday'),
         'Washington': (3, 22, 'Thursday')}

for city in tests:
    assert time_of_trip(example_trips[city], city) == tests[city]
    print('{} match successfully'.format(city))

def type_of_user(datum, city):
    """
    Takes as input a dictionary containing info about a single trip (datum) and
    its origin city (city) and returns the type of system user that made the
    trip.

    Remember that Washington has different category names compared to Chicago
    and NYC.
    """

    #YOUR CODE HERE
    if city == 'Washington':
        if datum['Member Type'] == 'Registered':
            user_type = 'Subscriber'
        else:
            user_type = 'Customer'
    else:
        user_type = datum['usertype']
    return user_type


#Some tests to check that your code works. There should be no output if all of
#the assertions pass. The `example_trips` dictionary was obtained from when
#you printed the first trip from each of the original data files.
tests = {'NYC': 'Customer',
         'Chicago': 'Subscriber',
         'Washington': 'Subscriber'}

for city in tests:
    assert type_of_user(example_trips[city], city) == tests[city]

def condense_data(in_file, out_file, city):
    """
    This function takes full data from the specified input file
    and writes the condensed data to a specified output file. The city
    argument determines how the input file will be parsed.

    HINT: See the cell below to see how the arguments are structured!
    """

    with open(out_file, 'w') as f_out, open(in_file, 'r') as f_in:
        # set up csv DictWriter object - writer requires column names for the
        # first row as the "fieldnames" argument
        out_colnames = ['duration', 'month', 'hour', 'day_of_week', 'user_type']
        trip_writer = csv.DictWriter(f_out, fieldnames = out_colnames)
        trip_writer.writeheader()

        ## TODO: set up csv DictReader object ##
        trip_reader = csv.DictReader(f_in)

        # collect data from and process each row
        for row in trip_reader:
            # set up a dictionary to hold the values for the cleaned and trimmed
            # data point
            new_point = {}

            ## TODO: use the helper functions to get the cleaned data from  ##
            ## the original data dictionaries.                              ##
            ## Note that the keys for the new_point dictionary should match ##
            ## the column names set in the DictWriter object above.         ##
            new_point['duration'] = duration_in_mins(row, city)
            new_point['month'] = time_of_trip(row, city)[0]
            new_point['hour'] = time_of_trip(row, city)[1]
            new_point['day_of_week'] = time_of_trip(row, city)[2]
            new_point['user_type'] = type_of_user(row, city)
            print(new_point) # Debug point

            ## TODO: write the processed information to the output file.     ##
            ## see https://docs.python.org/3/library/csv.html#writer-objects ##
            trip_writer.writerow(new_point)

city_info = {'Washington': {'in_file': './Documents/Udacity/Project2/Washington-CapitalBikeshare-2016.csv',
                            'out_file': './Documents/Udacity/Project2/Washington-2016-Summary.csv'},
             'Chicago': {'in_file': './Documents/Udacity/Project2/Chicago-Divvy-2016.csv',
                         'out_file': './Documents/Udacity/Project2/Chicago-2016-Summary.csv'},
             'NYC': {'in_file': './Documents/Udacity/Project2/NYC-CitiBike-2016.csv',
                     'out_file': './Documents/Udacity/Project2/NYC-CitiBike-2016-summary.csv'}}

for city, filenames in city_info.items():
    print('Start to write {}'.format(city))
    condense_data(filenames['in_file'], filenames['out_file'], city)
    print_first_point(filenames['out_file'])

def number_of_trips(filename):
    """
    This function reads in a file with trip data and reports the number of
    trips made by subscribers, customers, and total overall.
    """
    with open(filename, 'r') as f_in:
        # set up csv reader object
        reader = csv.DictReader(f_in)

        # initialize count variables
        n_subscribers = 0
        n_customers = 0

        # tally up ride types
        for row in reader:
            if row['user_type'] == 'Subscriber':
                n_subscribers += 1
            else:
                n_customers += 1

        # compute total number of rides
        n_total = n_subscribers + n_customers

        # return tallies as a tuple
        return(n_subscribers, n_customers, n_total)

data_file = ['./Documents/Udacity/Project2/NYC-CitiBike-2016-summary.csv',
            './Documents/Udacity/Project2/Washington-2016-Summary.csv',
            './Documents/Udacity/Project2/Chicago-2016-Summary.csv']

for city in data_file:
    print('number of trips: {}.'.format(number_of_trips(data_file)))
