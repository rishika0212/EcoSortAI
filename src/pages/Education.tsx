import React from "react";

const Education = () => {
  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
      <h1 className="text-3xl font-bold text-gray-900 mb-8">
        Recycling Education
      </h1>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
        {/* PET */}
        <div className="bg-white rounded-lg shadow-md p-6">
          <h2 className="text-xl font-semibold text-primary-600 mb-4">
            PET (Polyethylene Terephthalate)
          </h2>
          <p className="text-gray-600 mb-4">
            Commonly used in water bottles and food containers. PET is fully
            recyclable and can be turned into new bottles, clothing, and carpet
            fibers.
          </p>
          <ul className="list-disc list-inside text-gray-600">
            <li>Rinse containers before recycling</li>
            <li>Remove caps and labels</li>
            <li>Flatten to save space</li>
          </ul>
        </div>

        {/* HDPE */}
        <div className="bg-white rounded-lg shadow-md p-6">
          <h2 className="text-xl font-semibold text-primary-600 mb-4">
            HDPE (High-Density Polyethylene)
          </h2>
          <p className="text-gray-600 mb-4">
            Used in milk jugs, detergent bottles, and plastic bags. HDPE is one
            of the most commonly recycled plastics.
          </p>
          <ul className="list-disc list-inside text-gray-600">
            <li>Clean and dry before recycling</li>
            <li>Remove any food residue</li>
            <li>Check local recycling guidelines</li>
          </ul>
        </div>

        {/* LDPE */}
        <div className="bg-white rounded-lg shadow-md p-6">
          <h2 className="text-xl font-semibold text-primary-600 mb-4">
            LDPE (Low-Density Polyethylene)
          </h2>
          <p className="text-gray-600 mb-4">
            Found in plastic bags, shrink wrap, and squeezable bottles. LDPE is
            recyclable but not all facilities accept it.
          </p>
          <ul className="list-disc list-inside text-gray-600">
            <li>Clean and dry plastic bags</li>
            <li>Bundle similar items together</li>
            <li>Check with local recycling centers</li>
          </ul>
        </div>

        {/* PP */}
        <div className="bg-white rounded-lg shadow-md p-6">
          <h2 className="text-xl font-semibold text-primary-600 mb-4">
            PP (Polypropylene)
          </h2>
          <p className="text-gray-600 mb-4">
            Used in yogurt containers, medicine bottles, and bottle caps. PP is
            becoming more widely accepted in recycling programs.
          </p>
          <ul className="list-disc list-inside text-gray-600">
            <li>Clean containers thoroughly</li>
            <li>Remove any food residue</li>
            <li>Check local recycling guidelines</li>
          </ul>
        </div>

        {/* PS */}
        <div className="bg-white rounded-lg shadow-md p-6">
          <h2 className="text-xl font-semibold text-primary-600 mb-4">
            PS (Polystyrene)
          </h2>
          <p className="text-gray-600 mb-4">
            Found in foam cups, take-out containers, and packaging materials. PS
            is difficult to recycle and often not accepted.
          </p>
          <ul className="list-disc list-inside text-gray-600">
            <li>Check local recycling guidelines</li>
            <li>Consider reusable alternatives</li>
            <li>Reduce usage when possible</li>
          </ul>
        </div>

        {/* General Tips */}
        <div className="bg-white rounded-lg shadow-md p-6">
          <h2 className="text-xl font-semibold text-primary-600 mb-4">
            General Recycling Tips
          </h2>
          <p className="text-gray-600 mb-4">
            Follow these general guidelines for better recycling practices.
          </p>
          <ul className="list-disc list-inside text-gray-600">
            <li>Clean and dry all recyclables</li>
            <li>Check local recycling guidelines</li>
            <li>When in doubt, throw it out</li>
            <li>Reduce and reuse when possible</li>
          </ul>
        </div>
      </div>
    </div>
  );
};

export default Education;
