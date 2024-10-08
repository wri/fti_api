# == Schema Information
#
# Table name: protected_areas
#
#  id         :bigint           not null, primary key
#  country_id :bigint           not null
#  name       :string           not null
#  wdpa_pid   :string           not null
#  geojson    :jsonb            not null
#  geometry   :geometry         geometry, 0
#  centroid   :geometry         point, 0
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
FactoryBot.define do
  factory :protected_area do
    country
    wdpa_pid { "1232" }
    name { "Name" }
    geojson {
      {
        type: "Feature",
        geometry: {
          type: "Polygon",
          coordinates: [
            [
              [
                18.03955078125,
                51.11041991029264
              ],
              [
                17.42431640625,
                50.331436330838834
              ],
              [
                17.99560546875,
                49.79544988802771
              ],
              [
                19.62158203125,
                49.89463439573421
              ],
              [
                20.0830078125,
                50.42951794712287
              ],
              [
                19.6875,
                51.08282186160978
              ],
              [
                18.91845703125,
                51.31688050404585
              ],
              [
                18.03955078125,
                51.11041991029264
              ]
            ]
          ]
        }
      }
    }
  end
end
