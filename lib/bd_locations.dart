// বাংলাদেশের বিভাগ, জেলা ও উপজেলা/থানার তালিকা
class BdLocations {
  static const String otherLabel = 'অন্যান্য (তালিকায় নেই)';

  static const Map<String, List<String>> districtsByDivision = {
    'Dhaka': [
      'Dhaka', 'Faridpur', 'Gazipur', 'Gopalganj', 'Kishoreganj', 'Madaripur',
      'Manikganj', 'Munshiganj', 'Narayanganj', 'Narsingdi', 'Rajbari',
      'Shariatpur', 'Tangail',
    ],
    'Chattogram': [
      'Bandarban', 'Brahmanbaria', 'Chandpur', 'Chattogram', 'Cumilla',
      "Cox's Bazar", 'Feni', 'Khagrachhari', 'Lakshmipur', 'Noakhali',
      'Rangamati',
    ],
    'Rajshahi': [
      'Bogura', 'Joypurhat', 'Naogaon', 'Natore', 'Chapainawabganj', 'Pabna',
      'Rajshahi', 'Sirajganj',
    ],
    'Khulna': [
      'Bagerhat', 'Chuadanga', 'Jashore', 'Jhenaidah', 'Khulna', 'Kushtia',
      'Magura', 'Meherpur', 'Narail', 'Satkhira',
    ],
    'Barishal': [
      'Barguna', 'Barishal', 'Bhola', 'Jhalokathi', 'Patuakhali', 'Pirojpur',
    ],
    'Sylhet': ['Habiganj', 'Moulvibazar', 'Sunamganj', 'Sylhet'],
    'Rangpur': [
      'Dinajpur', 'Gaibandha', 'Kurigram', 'Lalmonirhat', 'Nilphamari',
      'Panchagarh', 'Rangpur', 'Thakurgaon',
    ],
    'Mymensingh': ['Jamalpur', 'Mymensingh', 'Netrokona', 'Sherpur'],
  };

  static const Map<String, List<String>> upazilasByDistrict = {
    // ঢাকা বিভাগ
    'Dhaka': [
      'ঢাকা মহানগর', 'Dhamrai', 'Dohar', 'Keraniganj', 'Nawabganj', 'Savar',
    ],
    'Faridpur': [
      'Alfadanga', 'Boalmari', 'Charbhadrasan', 'Faridpur Sadar', 'Madhukhali',
      'Nagarkanda', 'Sadarpur', 'Saltha',
    ],
    'Gazipur': [
      'Gazipur Sadar', 'Kaliakair', 'Kaliganj', 'Kapasia', 'Sreepur',
    ],
    'Gopalganj': [
      'Gopalganj Sadar', 'Kashiani', 'Kotalipara', 'Muksudpur', 'Tungipara',
    ],
    'Kishoreganj': [
      'Austagram', 'Bajitpur', 'Bhairab', 'Hossainpur', 'Itna', 'Karimganj',
      'Katiadi', 'Kishoreganj Sadar', 'Kuliarchar', 'Mithamain', 'Nikli',
      'Pakundia', 'Tarail',
    ],
    'Madaripur': [
      'Kalkini', 'Madaripur Sadar', 'Rajoir', 'Shibchar',
    ],
    'Manikganj': [
      'Daulatpur', 'Ghior', 'Harirampur', 'Manikganj Sadar', 'Saturia',
      'Shibalaya', 'Singair',
    ],
    'Munshiganj': [
      'Gazaria', 'Lohajang', 'Munshiganj Sadar', 'Sirajdikhan', 'Sreenagar',
      'Tongibari',
    ],
    'Narayanganj': [
      'Araihazar', 'Bandar', 'Narayanganj Sadar', 'Rupganj', 'Sonargaon',
    ],
    'Narsingdi': [
      'Belabo', 'Monohardi', 'Narsingdi Sadar', 'Palash', 'Raipura', 'Shibpur',
    ],
    'Rajbari': [
      'Baliakandi', 'Goalanda', 'Kalukhali', 'Pangsha', 'Rajbari Sadar',
    ],
    'Shariatpur': [
      'Bhedarganj', 'Damudya', 'Gosairhat', 'Naria', 'Shariatpur Sadar', 'Zajira',
    ],
    'Tangail': [
      'Basail', 'Bhuapur', 'Delduar', 'Dhanbari', 'Ghatail', 'Gopalpur',
      'Kalihati', 'Madhupur', 'Mirzapur', 'Nagarpur', 'Sakhipur', 'Tangail Sadar',
    ],

    // চট্টগ্রাম বিভাগ
    'Bandarban': [
      'Ali Kadam', 'Bandarban Sadar', 'Lama', 'Naikhongchhari', 'Rowangchhari',
      'Ruma', 'Thanchi',
    ],
    'Brahmanbaria': [
      'Akhaura', 'Ashuganj', 'Bancharampur', 'Bijoynagar', 'Brahmanbaria Sadar',
      'Kasba', 'Nabinagar', 'Nasirnagar', 'Sarail',
    ],
    'Chandpur': [
      'Chandpur Sadar', 'Faridganj', 'Haimchar', 'Hajiganj', 'Haziganj',
      'Kachua', 'Matlab Dakshin', 'Matlab Uttar', 'Shahrasti',
    ],
    'Chattogram': [
      'চট্টগ্রাম মহানগর', 'Anwara', 'Banshkhali', 'Boalkhali', 'Chandanaish',
      'Fatikchhari', 'Hathazari', 'Lohagara', 'Mirsharai', 'Patiya', 'Rangunia',
      'Raozan', 'Sandwip', 'Satkania', 'Sitakunda',
    ],
    'Cumilla': [
      'Barura', 'Brahmanpara', 'Burichang', 'Chandina', 'Chauddagram',
      'Cumilla Sadar', 'Cumilla Sadar Dakshin', 'Daudkandi', 'Debidwar', 'Homna',
      'Laksam', 'Lalmai', 'Meghna', 'Monohargonj', 'Muradnagar', 'Nangalkot',
      'Titas',
    ],
    "Cox's Bazar": [
      'Chakaria', "Cox's Bazar Sadar", 'Kutubdia', 'Maheshkhali', 'Pekua',
      'Ramu', 'Teknaf', 'Ukhia',
    ],
    'Feni': [
      'Chhagalnaiya', 'Daganbhuiyan', 'Feni Sadar', 'Fulgazi', 'Parshuram',
      'Sonagazi',
    ],
    'Khagrachhari': [
      'Dighinala', 'Khagrachhari Sadar', 'Lakshmichhari', 'Mahalchhari',
      'Manikchhari', 'Matiranga', 'Panchhari', 'Ramgarh',
    ],
    'Lakshmipur': [
      'Kamalnagar', 'Lakshmipur Sadar', 'Raipur', 'Ramganj', 'Ramgati',
    ],
    'Noakhali': [
      'Begumganj', 'Chatkhil', 'Companiganj', 'Hatiya', 'Kabirhat',
      'Noakhali Sadar', 'Senbagh', 'Sonaimuri', 'Subarnachar',
    ],
    'Rangamati': [
      'Baghaichhari', 'Barkal', 'Belaichhari', 'Juraichhari', 'Kaptai',
      'Kawkhali', 'Langadu', 'Naniarchar', 'Rajasthali', 'Rangamati Sadar',
    ],

    // রাজশাহী বিভাগ
    'Bogura': [
      'Adamdighi', 'Bogura Sadar', 'Dhunat', 'Dhupchanchia', 'Gabtali',
      'Kahaloo', 'Nandigram', 'Sariakandi', 'Shajahanpur', 'Sherpur', 'Shibganj',
      'Sonatala',
    ],
    'Joypurhat': [
      'Akkelpur', 'Joypurhat Sadar', 'Kalai', 'Khetlal', 'Panchbibi',
    ],
    'Naogaon': [
      'Atrai', 'Badalgachhi', 'Dhamoirhat', 'Mahadebpur', 'Manda',
      'Naogaon Sadar', 'Niamatpur', 'Patnitala', 'Porsha', 'Raninagar', 'Sapahar',
    ],
    'Natore': [
      'Bagatipara', 'Baraigram', 'Gurudaspur', 'Lalpur', 'Naldanga',
      'Natore Sadar', 'Singra',
    ],
    'Chapainawabganj': [
      'Bholahat', 'Chapainawabganj Sadar', 'Gomastapur', 'Nachole', 'Shibganj',
    ],
    'Pabna': [
      'Atgharia', 'Bera', 'Bhangura', 'Chatmohar', 'Faridpur', 'Ishwardi',
      'Pabna Sadar', 'Santhia', 'Sujanagar',
    ],
    'Rajshahi': [
      'রাজশাহী মহানগর', 'Bagha', 'Bagmara', 'Charghat', 'Durgapur', 'Godagari',
      'Mohanpur', 'Paba', 'Puthia', 'Tanore',
    ],
    'Sirajganj': [
      'Belkuchi', 'Chauhali', 'Kamarkhanda', 'Kazipur', 'Raiganj',
      'Shahjadpur', 'Sirajganj Sadar', 'Tarash', 'Ullah Para',
    ],

    // খুলনা বিভাগ
    'Bagerhat': [
      'Bagerhat Sadar', 'Chitalmari', 'Fakirhat', 'Kachua', 'Mollahat', 'Mongla',
      'Morrelganj', 'Rampal', 'Sarankhola',
    ],
    'Chuadanga': [
      'Alamdanga', 'Chuadanga Sadar', 'Damurhuda', 'Jibannagar',
    ],
    'Jashore': [
      'Abhaynagar', 'Bagherpara', 'Chaugachha', 'Jashore Sadar', 'Jhikargachha',
      'Keshabpur', 'Manirampur', 'Sharsha',
    ],
    'Jhenaidah': [
      'Harinakunda', 'Jhenaidah Sadar', 'Kaliganj', 'Kotchandpur', 'Maheshpur',
      'Shailkupa',
    ],
    'Khulna': [
      'খুলনা মহানগর', 'Batiaghata', 'Dacope', 'Dighalia', 'Dumuria', 'Koyra',
      'Paikgachha', 'Phultala', 'Rupsa', 'Terokhada',
    ],
    'Kushtia': [
      'Bheramara', 'Daulatpur', 'Khoksa', 'Kumarkhali', 'Kushtia Sadar', 'Mirpur',
    ],
    'Magura': [
      'Magura Sadar', 'Mohammadpur', 'Shalikha', 'Sreepur',
    ],
    'Meherpur': [
      'Gangni', 'Meherpur Sadar', 'Mujibnagar',
    ],
    'Narail': [
      'Kalia', 'Lohagara', 'Narail Sadar',
    ],
    'Satkhira': [
      'Assasuni', 'Debhata', 'Kalaroa', 'Kaliganj', 'Satkhira Sadar',
      'Shyamnagar', 'Tala',
    ],

    // বরিশাল বিভাগ
    'Barguna': [
      'Amtali', 'Bamna', 'Barguna Sadar', 'Betagi', 'Patharghata', 'Taltali',
    ],
    'Barishal': [
      'বরিশাল মহানগর', 'Agailjhara', 'Babuganj', 'Bakerganj', 'Banaripara',
      'Gaurnadi', 'Hizla', 'Mehendiganj', 'Muladi', 'Wazirpur',
    ],
    'Bhola': [
      'Bhola Sadar', 'Burhanuddin', 'Char Fasson', 'Daulatkhan', 'Lalmohan',
      'Manpura', 'Tazumuddin',
    ],
    'Jhalokathi': [
      'Jhalokathi Sadar', 'Kathalia', 'Nalchity', 'Rajapur',
    ],
    'Patuakhali': [
      'Bauphal', 'Dashmina', 'Dumki', 'Galachipa', 'Kalapara', 'Mirzaganj',
      'Patuakhali Sadar', 'Rangabali',
    ],
    'Pirojpur': [
      'Bhandaria', 'Kawkhali', 'Mathbaria', 'Nazirpur', 'Nesarabad',
      'Pirojpur Sadar', 'Zianagar',
    ],

    // সিলেট বিভাগ
    'Habiganj': [
      'Ajmiriganj', 'Bahubal', 'Baniyachong', 'Chunarughat', 'Habiganj Sadar',
      'Lakhai', 'Madhabpur', 'Nabiganj', 'Sayestaganj',
    ],
    'Moulvibazar': [
      'Barlekha', 'Juri', 'Kamalganj', 'Kulaura', 'Moulvibazar Sadar',
      'Rajnagar', 'Sreemangal',
    ],
    'Sunamganj': [
      'Bishwamvarpur', 'Chhatak', 'Dakshin Sunamganj', 'Derai', 'Dharampasha',
      'Dowarabazar', 'Jagannathpur', 'Jamalganj', 'Sullah', 'Sunamganj Sadar',
      'Tahirpur',
    ],
    'Sylhet': [
      'সিলেট মহানগর', 'Balaganj', 'Beanibazar', 'Bishwanath', 'Companiganj',
      'Dakshin Surma', 'Fenchuganj', 'Golapganj', 'Gowainghat', 'Jaintiapur',
      'Kanaighat', 'Osmani Nagar', 'Sylhet Sadar', 'Zakiganj',
    ],

    // রংপুর বিভাগ
    'Dinajpur': [
      'Birampur', 'Biral', 'Birganj', 'Bochaganj', 'Chirirbandar', 'Dinajpur Sadar',
      'Ghoraghat', 'Hakimpur', 'Kaharole', 'Khansama', 'Nawabganj', 'Parbatipur',
      'Phulbari',
    ],
    'Gaibandha': [
      'Gaibandha Sadar', 'Gobindaganj', 'Palashbari', 'Phulchhari', 'Sadullapur',
      'Sughatta', 'Sundarganj',
    ],
    'Kurigram': [
      'Bhurungamari', 'Char Rajibpur', 'Chilmari', 'Kurigram Sadar', 'Nageshwari',
      'Phulbari', 'Rajarhat', 'Raumari', 'Ulipur',
    ],
    'Lalmonirhat': [
      'Aditmari', 'Hatibandha', 'Kaliganj', 'Lalmonirhat Sadar', 'Patgram',
    ],
    'Nilphamari': [
      'Dimla', 'Domar', 'Jaldhaka', 'Kishoreganj', 'Nilphamari Sadar', 'Saidpur',
    ],
    'Panchagarh': [
      'Atwari', 'Boda', 'Debiganj', 'Panchagarh Sadar', 'Tetulia',
    ],
    'Rangpur': [
      'রংপুর মহানগর', 'Badarganj', 'Gangachara', 'Kaunia', 'Mithapukur',
      'Pirganj', 'Pirgachha', 'Rangpur Sadar', 'Taraganj',
    ],
    'Thakurgaon': [
      'Baliadangi', 'Haripur', 'Pirganj', 'Ranisankail', 'Thakurgaon Sadar',
    ],

    // ময়মনসিংহ বিভাগ
    'Jamalpur': [
      'Bakshiganj', 'Dewanganj', 'Islampur', 'Jamalpur Sadar', 'Madarganj',
      'Melandaha', 'Sarishabari',
    ],
    'Mymensingh': [
      'ময়মনসিংহ মহানগর', 'Bhaluka', 'Dhobaura', 'Fulbaria', 'Gaffargaon',
      'Gauripur', 'Haluaghat', 'Ishwarganj', 'Muktagachha', 'Nandail',
      'Phulpur', 'Tarakanda', 'Trishal',
    ],
    'Netrokona': [
      'Atpara', 'Barhatta', 'Durgapur', 'Kalmakanda', 'Kendua', 'Khaliajuri',
      'Madan', 'Mohanganj', 'Netrokona Sadar', 'Purbadhala',
    ],
    'Sherpur': [
      'Jhenaigati', 'Nakla', 'Nalitabari', 'Sherpur Sadar', 'Sreebardi',
    ],
  };

  static List<String> get divisions => districtsByDivision.keys.toList();

  static List<String> upazilasOf(String district) {
    final list = upazilasByDistrict[district] ?? const <String>[];
    return [...list, otherLabel];
  }
}
